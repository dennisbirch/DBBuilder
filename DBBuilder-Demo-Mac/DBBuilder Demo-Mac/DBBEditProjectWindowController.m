//
//  DBBEditProjectWindowController.m
//  DBBuilder-Mac
//
//  Created by Dennis Birch on 11/20/14.
//  Copyright (c) 2014 Dennis Birch. All rights reserved.
//

#import "DBBEditProjectWindowController.h"
#import "DBBProjectListWindowController.h"
#import "DBBMeetingListController.h"
#import "DBBProject.h"
#import "DBBMeeting.h"

@interface DBBEditProjectWindowController () <NSTextFieldDelegate, NSTableViewDelegate, NSTableViewDataSource, MeetingListWindowDelegate>

@property (nonatomic, weak) IBOutlet NSTextField *nameTextField;
@property (nonatomic, weak) IBOutlet NSTextField *codeTextField;
@property (nonatomic, weak) IBOutlet NSDatePicker *startDatePicker;
@property (nonatomic, weak) IBOutlet NSDatePicker *endDatePicker;
@property (nonatomic, weak) IBOutlet NSTableView *meetingsTable;
@property (nonatomic, weak) IBOutlet NSTextField *budgetField;
@property (nonatomic, weak) IBOutlet NSTextField *tagsField;
@property (nonatomic, weak) IBOutlet NSTextField *subprojectLabel;
@property (nonatomic, weak) IBOutlet NSButton *setButton;
@property (nonatomic, weak) IBOutlet NSButton *saveButton;

@property (nonatomic, strong) NSTextField *activeTextField;

@property (nonatomic, strong) DBBMeetingListController *mtgListWindowController;

@end

@implementation DBBEditProjectWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleTextChangedNotification:) name:NSControlTextDidChangeNotification object:nil];
	
	[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleWindowWillCloseNotification:) name:NSWindowWillCloseNotification object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWindowActivationNotification:) name:NSWindowDidBecomeKeyNotification object:nil];
	

 	self.nameTextField.delegate = self;
	self.codeTextField.delegate = self;
	self.budgetField.delegate = self;
	self.tagsField.delegate = self;
	
	if (self.project != nil && self.project.itemID > 0) {
		[self.nameTextField setStringValue:self.project.name];
		[self.codeTextField setStringValue:self.project.code];
		[self.startDatePicker setDateValue:self.project.startDate];
		[self.endDatePicker setDateValue:self.project.endDate];
		if (self.project.tags != nil) {
			[self loadTags];
		}
		[self.budgetField setStringValue:[self formatCurrency:[self.project.budget doubleValue]]];
		[self.meetingsTable reloadData];
		self.window.title = @"Edit Project";
	} else {
		self.project = [[DBBProject alloc] initWithManager:[DBManager defaultDBManager]];
		self.project.startDate = [NSDate date];
		self.project.endDate = [NSDate date];
		self.startDatePicker.dateValue = self.project.startDate;
		self.endDatePicker.dateValue = self.project.endDate;
		self.window.title = @"Add Project";
	}
	
	[self.project makeClean];
	[self enableSaveButton];
	[self updateSetSubprojectButtonTitle];
	
	[self.meetingsTable.tableColumns[0] setWidth:self.meetingsTable.frame.size.width];
}


- (IBAction)didSetStartDate:(id)sender
{
	NSDatePicker *picker = sender;
	self.project.startDate = picker.dateValue;
	[self.project makeDirty];
	[self enableSaveButton];
}

- (IBAction)didSetEndDate:(id)sender
{
	NSDatePicker *picker = sender;
	self.project.endDate = picker.dateValue;
	[self.project makeDirty];
	[self enableSaveButton];
}

- (IBAction)clickedSetClearButton:(id)sender
{
	NSButton *button = sender;
	if ([[button title] isEqualToString:@"Set"]) {
		DBBProjectListWindowController *listVC = (DBBProjectListWindowController *)self.delegate;
		[listVC setupForSubprojectSelectionWithParentProject:self.project];
		[self showMainWindow];
	} else {
		self.project.subProject = nil;
		[self.subprojectLabel setStringValue:@""];
	}
	
	[self updateSetSubprojectButtonTitle];
}

- (IBAction)saveChanges:(id)sender
{
	[self.project saveToDB];
	[self showMainWindow];
	[self.window close];
	[self.delegate closedProjectEditorWindow:self];
}

- (IBAction)cancelChanges:(id)sender
{
	[self showMainWindow];
	[self.window close];
	[self.delegate closedProjectEditorWindow:self];
}

- (IBAction)addMeetingsButtonClicked:(id)sender
{
	self.mtgListWindowController = [[DBBMeetingListController alloc] initWithWindowNibName:@"DBBMeetingListController"];
	self.mtgListWindowController.project = self.project;
	self.mtgListWindowController.delegate = self;
	[self.mtgListWindowController showWindow:nil];
	[self.window setIsVisible:NO];
}

- (void)showMainWindow
{
	DBBProjectListWindowController *listVC = (DBBProjectListWindowController *)self.delegate;
	[listVC showWindow:nil];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return (int)self.project.meetings.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	DBBMeeting *meeting = self.project.meetings[(unsigned)row];
	return meeting.purpose;
}

- (void)enableSaveButton
{
	BOOL enable = self.project.name.length > 0 && self.project.code.length > 0 && [self.project.startDate laterDate:self.project.endDate] == self.project.endDate;
	
	[self.saveButton setEnabled:enable];
}


- (void)handleTextChangedNotification:(NSNotification *)notification
{
	if (self.activeTextField == self.nameTextField) {
		self.project.name = [self.nameTextField stringValue];
	} else if (self.activeTextField == self.codeTextField) {
		self.project.code = [self.codeTextField stringValue];
	} else if (self.activeTextField == self.budgetField) {
		NSString *text = [[self.budgetField stringValue] stringByReplacingOccurrencesOfString:@"$" withString:@""];
		self.project.budget = [NSDecimalNumber decimalNumberWithString:text];
	}
	
	[self.project makeDirty];
	[self enableSaveButton];
}

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor
{
	self.activeTextField = (NSTextField *)control;
	return YES;
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	if (control == (NSTextField *)self.budgetField) {
		double budgetAmount = [self.project.budget doubleValue];
		[self.budgetField setStringValue:[self formatCurrency:budgetAmount]];

	} else if (control == (NSTextField *)self.tagsField) {
		NSString *text = [[self.tagsField stringValue]stringByReplacingOccurrencesOfString:@"," withString:@" "];
		self.project.tags = [text componentsSeparatedByString:@" "];
		[self loadTags];
	}
	self.activeTextField = nil;
	return YES;
}

- (void)loadTags
{
	NSMutableArray *temp = [NSMutableArray new];
	[self.project.tags enumerateObjectsUsingBlock:^(NSString *tag, NSUInteger idx, BOOL *stop) {
		if ([tag stringByReplacingOccurrencesOfString:@" " withString:@""].length > 0) {
			[temp addObject:[tag stringByReplacingOccurrencesOfString:@" " withString:@""]];
		}
	}];
	
	[self.tagsField setStringValue:[temp componentsJoinedByString:@" "]];
}

- (NSString *)formatCurrency:(double)currencyAmount
{
	static NSNumberFormatter *formatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		formatter = [[NSNumberFormatter alloc] init];
		formatter.numberStyle = NSNumberFormatterCurrencyStyle;
	});
	
	return [formatter stringFromNumber:@(currencyAmount)];
}

- (void)handleWindowWillCloseNotification:(NSNotification *)notification
{
	[self.activeTextField resignFirstResponder];
}

- (void)handleWindowActivationNotification:(NSNotification *)notification
{
	NSString *subproject = (self.project.subProject == nil) ? @"" : self.project.subProject.name;
	[self.subprojectLabel setStringValue:subproject];
}

- (void)updateSetSubprojectButtonTitle
{
	NSString *btnTitle = (self.project.subProject == nil) ? @"Set" : @"Clear";
	[self.setButton setTitle:btnTitle];
}

- (void)didCloseMeetingListWindow:(DBBMeetingListController *)meetingListWindow
{
	[self.meetingsTable reloadData];
	[self.window setIsVisible:YES];
}

@end
