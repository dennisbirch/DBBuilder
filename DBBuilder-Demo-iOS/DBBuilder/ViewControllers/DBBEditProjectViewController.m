//
//  DBBEditProjectViewController.m
//  DBBuilder
//
//  Created by Dennis Birch on 11/10/14.
//  Copyright (c) 2014 Dennis Birch. All rights reserved.
//

#import "DBBEditProjectViewController.h"
#import "DBBMeetingListViewController.h"
#import "DBBProjectListViewController.h"
#import "DBBProject.h"
#import "DBBMeeting.h"
#import "DBBDatePickerView.h"
#import "NSDate+DBExtensions.h"

@interface DBBEditProjectViewController () <UITextFieldDelegate, DatePickerViewDelegate>

@property (nonatomic, weak) IBOutlet UILabel *startLabel;
@property (nonatomic, weak) IBOutlet UILabel *stopLabel;
@property (nonatomic, weak) IBOutlet UILabel *meetingsLabel;
@property (nonatomic, weak) IBOutlet UITextField *nameField;
@property (nonatomic, weak) IBOutlet UITextField *codeField;
@property (nonatomic, weak) IBOutlet UITextField *budgetField;
@property (nonatomic, weak) IBOutlet UITextField *tagsField;
@property (nonatomic, weak) IBOutlet UIButton *subProjectButton;
@property (nonatomic, weak) IBOutlet UILabel *subProjectLabel;

@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *stopDate;
@property (nonatomic, strong) DBBDatePickerView *datePickerView;
@property (nonatomic, strong) UITextField *activeTextField;

@property (nonatomic, assign) BOOL shouldDeferSaving;

@end

typedef NS_ENUM(NSUInteger, ProjectEditTableSection) {
	ProjectEditTableSectionName,
	ProjectEditTableSectionCode,
	ProjectEditTableSectionStartDate,
	ProjectEditTableSectionEndDate,
	ProjectEditTableSectionBudget,
	ProjectEditTableSectionMeetings,
    ProjectEditTableSectionTags,
    ProjectEditTableSectionSubProject,
};


@implementation DBBEditProjectViewController

#define kSectionHeaderViewHeight	32.0

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	if (self.project != nil) {
		self.nameField.text = self.project.name;
		self.codeField.text = self.project.code;
		self.startLabel.text = [self.project.startDate db_displayDate];
		self.stopLabel.text = [self.project.endDate db_displayDate];
        [self displayBudget];
        self.tagsField.text = [self.project.tags componentsJoinedByString:@" "];
        self.startDate = self.project.startDate;
        self.stopDate = self.project.endDate;
	} else {
		self.project = [DBBProject new];
	}
	
	self.nameField.delegate = self;
	self.budgetField.delegate = self;
	self.codeField.delegate = self;
    self.tagsField.delegate = self;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChangeText:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	self.meetingsLabel.text = [self projectMeetings];
	self.shouldDeferSaving = NO;
    [self setupSubProjectControls];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	[self.activeTextField resignFirstResponder];
	
	if (self.shouldDeferSaving || !self.project.isDirty) {
		return;
	}
	
	// save meeting
	if (self.project.name.length > 0) {
		[self.project saveToDB];
	}
	
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	self.shouldDeferSaving = YES;
	
	if ([segue.identifier isEqualToString:@"EditMeetingsSegue"]) {
        DBBMeetingListViewController *vc = segue.destinationViewController;
		vc.project = self.project;
    } else if ([segue.identifier isEqualToString:@"SubprojectModalSegue"]) {
        DBBProjectListViewController *projListVC = segue.destinationViewController;
        projListVC.parentProject = self.project;
    }
}

#pragma mark - Actions

- (IBAction)subProjectButtonTapped:(id)sender
{
    if (self.project.subProject == nil) {
        [self performSegueWithIdentifier:@"SubprojectModalSegue" sender:self.project];
    } else {
        self.project.subProject = nil;
        [self.project makeDirty];
        [self setupSubProjectControls];
    }
}

- (void)setupSubProjectControls
{
    NSString *titleLabel = (self.project.subProject == nil) ? @"Set" : @"Clear";
    [self.subProjectButton setTitle:titleLabel forState:UIControlStateNormal];
    [self.subProjectButton sizeToFit];
    self.subProjectLabel.text = (self.project.subProject == nil) ? @"None" : self.project.subProject.name;
}

#pragma mark - Helpers

- (void)showDatePickerViewForSection:(NSInteger)section
{
	[self.activeTextField resignFirstResponder];
	
	NSDate *date;
	UILabel *label;
	if (section == ProjectEditTableSectionStartDate) {
		date = self.startDate;
		label = self.startLabel;
	} else {
		date = self.stopDate;
		label = self.stopLabel;
	}
	
	self.datePickerView = [[DBBDatePickerView alloc] initWithDate:date section:section];
	
	if (date == nil) {
		if (section == ProjectEditTableSectionStartDate) {
			self.startDate = [NSDate date];
			self.startLabel.text = [self.startDate db_displayDate];
		} else {
			self.stopDate = [NSDate date];
			self.stopLabel.text = [self.stopDate db_displayDate];
		}
	}
	
	CGRect frame = self.datePickerView.frame;
	CGRect labelFrame = [label convertRect:label.frame toView:self.view];
	frame.origin.y = labelFrame.origin.y - 60;
	self.datePickerView.frame = frame;
	self.datePickerView.tag = section;
	self.datePickerView.delegate = self;
	
	[self.view.window addSubview:self.datePickerView];
}

- (NSString *)projectMeetings
{
	NSMutableArray *meetings = [NSMutableArray new];
	
	for (DBBMeeting *meeting in self.project.meetings) {
		[meetings addObject:meeting.purpose];
	}
	
	return [meetings componentsJoinedByString:@", "];
}

- (void)displayBudget
{
    static NSNumberFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    });
    
    NSString *budgetStr = [formatter stringFromNumber:self.project.budget];
    self.budgetField.text = (self.project.budget > 0) ? budgetStr : @"";
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == ProjectEditTableSectionStartDate || indexPath.section == ProjectEditTableSectionEndDate) {
		[self showDatePickerViewForSection:indexPath.section];
	}
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
	if (self.project.name.length == 0) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Missing Name"
														message:@"Every project needs a name, but you haven't entered one for this project."
													   delegate:self
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
		return NO;
		
	}
	
	return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return kSectionHeaderViewHeight + 4.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	// make backing view
	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 10, self.view.bounds.size.width, kSectionHeaderViewHeight)];
	
	// make label
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 100, kSectionHeaderViewHeight)];
	NSString *sectionTitle;
	switch (section) {
		case ProjectEditTableSectionName:
			sectionTitle = @"NAME";
			break;
			
		case ProjectEditTableSectionCode:
			sectionTitle = @"CODE";
			break;
			
		case ProjectEditTableSectionStartDate:
			sectionTitle = @"START DATE";
			break;
			
		case ProjectEditTableSectionEndDate:
			sectionTitle = @"END DATE";
			break;
			
		case ProjectEditTableSectionBudget:
			sectionTitle = @"BUDGET";
			break;
			
		case ProjectEditTableSectionMeetings:
			sectionTitle = @"MEETINGS";
			break;
			
        case ProjectEditTableSectionTags:
            sectionTitle = @"TAGS";
            break;
            
        case ProjectEditTableSectionSubProject:
            sectionTitle = @"SUB-PROJECT";
            break;
            
		default:
			break;
	}
	
	label.text = sectionTitle;
	label.backgroundColor = [UIColor clearColor];
	label.textColor = [UIColor lightGrayColor];
	label.font = [UIFont systemFontOfSize:14];
	[view addSubview:label];
	
	return view;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	self.activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if (textField == self.nameField) {
		self.project.name = textField.text;
	} else if (textField == self.codeField) {
		self.project.code = textField.text;
	} else if (textField == self.budgetField) {
        NSString *budgetStr = [textField.text stringByReplacingOccurrencesOfString:@"$" withString:@""];
		self.project.budget = [NSDecimalNumber decimalNumberWithString:budgetStr];
        [self displayBudget];
    } else if (textField == self.tagsField) {
        NSString *temp = [textField.text stringByReplacingOccurrencesOfString:@"," withString:@" "];
        self.project.tags = [temp componentsSeparatedByString:@" "];
    }
	
	self.activeTextField = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	
	if (textField == self.nameField) {
		[self.codeField becomeFirstResponder];
	}

	return YES;
}

- (void)textFieldDidChangeText:(NSNotification *)notification
{
	if (self.activeTextField == self.nameField) {
		self.project.name = self.activeTextField.text;
	} else if (self.activeTextField == self.codeField) {
		self.project.code = self.activeTextField.text;
	} else if (self.activeTextField == self.budgetField) {
		self.project.budget = [NSDecimalNumber decimalNumberWithString:self.activeTextField.text];
	}

	[self.project makeDirty];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // check to make sure budget field entries are numbers or ".", but also allow backspace
    if (textField != self.budgetField || [string isEqualToString:@""]) {
        // slightly hacky, but works — "string" is empty if backspace key is typed
		return YES;
	}
	
    static NSCharacterSet *allowedKeys;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
        allowedKeys = [NSCharacterSet characterSetWithCharactersInString:@"0123456789."];
	});
	
    unichar c = [string characterAtIndex:0];;
    return [allowedKeys characterIsMember:c];
}

#pragma mark - DatePickerViewDelegate

- (void)datePickerView:(DBBDatePickerView *)datePickerView valueChanged:(NSDate *)newDate
{
	if (datePickerView.tag == ProjectEditTableSectionStartDate) {
        if (![self.startDate isEqual:newDate]) {
            [self.project makeDirty];
        }
		self.project.startDate = newDate;
		self.startDate = newDate;
		self.startLabel.text = [self.startDate db_displayDate];
	} else {
        if (![self.stopDate isEqual:newDate]) {
            [self.project makeDirty];
        }
		self.project.endDate = newDate;
		self.stopDate = newDate;
		self.stopLabel.text = [self.stopDate db_displayDate];
	}
	
	[self.project makeDirty];
}

- (void)didDismissDatePickerView:(DBBDatePickerView *)datePickerView
{
	[datePickerView removeFromSuperview];
	self.datePickerView = nil;
}



@end
