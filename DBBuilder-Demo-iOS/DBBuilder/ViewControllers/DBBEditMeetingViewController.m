//
//  DBBEditMeetingViewController.m
//  DBBuilder
//
//  Created by Dennis Birch on 10/20/13.
//  Copyright (c) 2013 Dennis Birch. All rights reserved.
//

#import "DBBEditMeetingViewController.h"
#import "DBBEditAttendeesTableViewController.h"
#import "DBBMeeting.h"
#import "DBBPerson.h"
#import "DBBDatePickerView.h"
#import "NSDate+DBExtensions.h"

@interface DBBEditMeetingViewController () <UITextFieldDelegate, DatePickerViewDelegate>

@property (nonatomic, weak) IBOutlet UITextField *meetingPurposeField;
@property (nonatomic, weak) IBOutlet UILabel *startLabel;
@property (nonatomic, weak) IBOutlet UILabel *stopLabel;
@property (nonatomic, weak) IBOutlet UILabel *participantsLabel;

@property (nonatomic, strong) DBBDatePickerView *datePickerView;

@property (nonatomic, strong) UITextField *activeTextField;

@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *stopDate;
@property (nonatomic, assign) BOOL hasSetStopTime;

@property (nonatomic, assign) BOOL shouldDeferSaving;

@end

@implementation DBBEditMeetingViewController

typedef NS_ENUM(NSInteger, TableSectionType) {
	TableSectionTypePurpose = 0,
	TableSectionTypeStartDate,
	TableSectionTypeStopDate,
	TableSectionTypeParticipants,
};

#define kParticipantsCellHeight		88.0
#define kDefaultTableCellHeight		44.0
#define kSectionHeaderViewHeight	32.0

#pragma mark - ViewController Lifecycle


- (void)viewDidLoad
{
    [super viewDidLoad];
    
	if (self.meeting != nil) {
		self.meetingPurposeField.text = self.meeting.purpose;
  		self.startLabel.text = [self.meeting.startTimeActual db_displayDateTime];
        self.stopLabel.text = [self.meeting.finishTimeActual db_displayDateTime];
        self.startDate = self.meeting.startTimeActual;
        self.stopDate = self.meeting.finishTimeActual;
		self.hasSetStopTime = self.meeting.itemID > 0;
	}

	self.meetingPurposeField.delegate = self;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChangeText:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.participantsLabel.text = [self participantNames];
	self.shouldDeferSaving = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
	
	// tidy up UI
	[self closeDatePickerView];
	[self.activeTextField resignFirstResponder];
	
	if (self.shouldDeferSaving) {
		return;
	}
    
    // save meeting
    if (self.meeting.purpose.length > 0) {
        [self.meeting saveToDB];
		[self.delegate meetingEditor:self savedMeeting:self.meeting];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Helpers

- (NSString *)participantNames
{
	NSMutableArray *namesArray = [NSMutableArray new];
	
	[self.meeting.participants enumerateObjectsUsingBlock:^(DBBPerson *person, NSUInteger idx, BOOL *stop) {
		NSString *fullName = [person fullName];
		[namesArray addObject:fullName];
	}];
	
    return [namesArray componentsJoinedByString:@", "];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	self.shouldDeferSaving = YES;
	DBBEditAttendeesTableViewController *vc = segue.destinationViewController;

	if ([segue.identifier isEqualToString:@"EditAttendees"]) {
        if (self.meeting == nil) {
            self.meeting = [[DBBMeeting alloc] init];
        }
        vc.meeting = self.meeting;
		vc.title = @"Edit Attendees";
	}
}


#pragma mark - UITableView


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == TableSectionTypeParticipants) {
         return kParticipantsCellHeight;
    }
	
    return kDefaultTableCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == TableSectionTypeStartDate || indexPath.section == TableSectionTypeStopDate) {
		[self showDatePickerViewForSection:indexPath.section];
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if (self.meeting.purpose.length == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Missing Title"
                                                        message:@"Every meeting needs a purpose, but you haven't entered one for this meeting."
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
        case TableSectionTypePurpose:
            sectionTitle = @"PURPOSE";
            break;
            
        case TableSectionTypeStartDate:
            sectionTitle = @"START TIME";
            break;
            
        case TableSectionTypeStopDate:
            sectionTitle = @"END TIME";
            break;
            
        case TableSectionTypeParticipants:
            sectionTitle = @"PARTICIPANTS";
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

#pragma mark - DatePickerView Display

- (void)showDatePickerViewForSection:(NSInteger)section
{
	[self.activeTextField resignFirstResponder];
	
	NSDate *date;
	UILabel *label;
	if (section == TableSectionTypeStartDate) {
		date = self.startDate;
		label = self.startLabel;
	} else {
		date = self.stopDate;
		label = self.stopLabel;
	}
	
	self.datePickerView = [[DBBDatePickerView alloc] initWithDate:date section:section];
	
	if (date == nil) {
		if (section == TableSectionTypeStartDate) {
			self.startDate = [NSDate date];
			self.startLabel.text = [self.startDate db_displayDateTime];
		} else {
			self.stopDate = [NSDate date];
			self.stopLabel.text = [self.stopDate db_displayDateTime];
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


#pragma mark - DatePickerViewDelegate

- (void)datePickerView:(DBBDatePickerView *)datePickerView valueChanged:(NSDate *)newDate
{
    if (datePickerView.tag == TableSectionTypeStartDate) {
        self.meeting.startTimeActual = newDate;
        self.startDate = newDate;
        self.startLabel.text = [self.startDate db_displayDateTime];
        
        if (!self.hasSetStopTime) {
            // match start and stop dates
            self.stopDate = [self.startDate copy];
			self.stopLabel.text = [self.stopDate db_displayDateTime];
        }
    } else {
        self.meeting.finishTimeActual = newDate;
        self.stopDate = newDate;
        self.stopLabel.text = [self.stopDate db_displayDateTime];
		self.hasSetStopTime = YES;
    }
    
    [self.meeting makeDirty];
}

- (void)didDismissDatePickerView:(DBBDatePickerView *)datePickerView
{
    [self closeDatePickerView];
}

- (void)closeDatePickerView
{
    [self.datePickerView removeFromSuperview];
    self.datePickerView = nil;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	self.activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if (textField == self.meetingPurposeField) {
		self.meeting.purpose = textField.text;
	}
	
	self.activeTextField = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField == self.meetingPurposeField) {
		[textField resignFirstResponder];
	}
	
	return YES;
}

- (void)textFieldDidChangeText:(NSNotification *)notification
{
	if (self.activeTextField == self.meetingPurposeField) {
		self.meeting.purpose = self.activeTextField.text;
		[self.meeting makeDirty];
	}
}

@end
