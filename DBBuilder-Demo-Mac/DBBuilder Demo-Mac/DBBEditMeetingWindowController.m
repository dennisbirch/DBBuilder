//
//  DBBEditMeetingWindowController.m
//  DBBuilder Demo-Mac
//
//  Created by Dennis Birch on 11/26/14.
//  Copyright (c) 2014 Dennis Birch. All rights reserved.
//

#import "DBBEditMeetingWindowController.h"
#import "DBBParticipantListWindowController.h"
#import "DBBMeeting.h"
#import "DBBPerson.h"
#import "NSDate+DBExtensions.h"

@interface DBBEditMeetingWindowController () <NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate, ParticipantListDelegate>

@property (nonatomic, weak) IBOutlet NSTextField *purposeField;
@property (nonatomic, weak) IBOutlet NSTextField *startTimeField;
@property (nonatomic, weak) IBOutlet NSTextField *endTimeField;
@property (nonatomic, weak) IBOutlet NSTableView *participantsTable;
@property (nonatomic, weak) IBOutlet NSDatePicker *startTimePicker;
@property (nonatomic, weak) IBOutlet NSDatePicker *endTimePicker;
@property (nonatomic, weak) IBOutlet NSButton *saveButton;
@property (nonatomic, assign) BOOL hasChangedEndTime;

@property (nonatomic, strong) NSTextField *activeTextField;

@property (nonatomic, strong) DBBParticipantListWindowController *participantListWindowController;

@end

@implementation DBBEditMeetingWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
	[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleTextChangedNotification:) name:NSControlTextDidChangeNotification object:nil];
	
	self.purposeField.delegate = self;
	self.startTimeField.delegate = self;
	self.endTimeField.delegate = self;
	
	if (self.meeting == nil) {
		NSDate *date = [NSDate date];
		self.meeting = [[DBBMeeting alloc] initWithManager:[DBManager defaultDBManager]];
		self.meeting.startTimeActual = date;
		self.meeting.finishTimeActual = date;
		self.startTimePicker.dateValue = date;
		self.endTimePicker.dateValue = date;
		[self.startTimeField setStringValue:[self timeStringForDate:date]];
		[self.endTimeField setStringValue:[self timeStringForDate:date]];
		self.hasChangedEndTime = NO;
	} else {
		[self.purposeField setStringValue:self.meeting.purpose];
		[self.startTimePicker setDateValue:self.meeting.startTimeActual];
		[self.startTimeField setStringValue:[self timeStringForDate:self.meeting.startTimeActual]];
		[self.endTimePicker setDateValue:self.meeting.finishTimeActual];
		[self.endTimeField setStringValue:[self timeStringForDate:self.meeting.finishTimeActual]];
		[self.participantsTable reloadData];
		self.hasChangedEndTime = YES;
	}
	
	[self enableSaveButton];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return (int)self.meeting.participants.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	DBBPerson *person = self.meeting.participants[(unsigned)row];
	return [person fullNameAndDepartment];
}

- (void)enableSaveButton
{
	BOOL enable = [self.purposeField stringValue].length > 0 &&
		[self.meeting.startTimeActual laterDate:self.meeting.finishTimeActual] == self.meeting.finishTimeActual;
	[self.saveButton setEnabled:enable];
}


- (void)handleTextChangedNotification:(NSNotification *)notification
{
	if (self.activeTextField == self.purposeField) {
		self.meeting.purpose = [self.purposeField stringValue];
	} else if (self.activeTextField == self.startTimeField) {
		self.meeting.startTimeActual = [self dateTime:self.startTimePicker.dateValue timeString:[self.startTimeField stringValue]];
	} else if (self.activeTextField == self.endTimeField) {
		self.meeting.finishTimeActual = [self dateTime:self.endTimePicker.dateValue timeString:[self.endTimeField stringValue]];
		self.hasChangedEndTime = YES;
	}
	
	[self.meeting makeDirty];
	[self enableSaveButton];
}

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor
{
	self.activeTextField = (NSTextField *)control;
	return YES;
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	self.activeTextField = nil;
	return YES;
}

- (IBAction)changedStartDate:(id)sender
{
	NSDatePicker *picker = sender;
	self.meeting.startTimeActual = [self dateTime:picker.dateValue timeString:[self.startTimeField stringValue]];
	[self enableSaveButton];
	if (!self.hasChangedEndTime) {
		self.endTimePicker.dateValue = picker.dateValue;
		self.meeting.finishTimeActual = [self dateTime:picker.dateValue timeString:[self.endTimeField stringValue]];
	}
}

- (IBAction)changedEndDate:(id)sender
{
	NSDatePicker *picker = sender;
	self.meeting.finishTimeActual = [self dateTime:picker.dateValue timeString:[self.endTimeField stringValue]];
	[self enableSaveButton];
	self.hasChangedEndTime = YES;
}

- (IBAction)addParticipantsButtonClicked:(id)sender
{
	self.participantListWindowController = [[DBBParticipantListWindowController alloc] initWithWindowNibName:@"DBBParticipantListWindowController"];
	self.participantListWindowController.delegate = self;
	self.participantListWindowController.meeting = self.meeting;
	[self.window setIsVisible:NO];
	[self.participantListWindowController showWindow:nil];
}

- (IBAction)saveChanges:(id)sender
{
	[self.meeting saveToDB];
	[self cancelClose:nil];
}

- (IBAction)cancelClose:(id)sender
{
	[self.window close];	
	[self.delegate didCloseMeetingEditor:self];
}


#pragma mark - Time Helpers

- (NSString *)timeStringForDate:(NSDate *)date
{
	static NSDateFormatter *timeFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		timeFormatter = [[NSDateFormatter alloc] init];
		timeFormatter.dateStyle = NSDateFormatterNoStyle;
		timeFormatter.timeStyle = NSDateFormatterShortStyle;
	});
	
	return [timeFormatter stringFromDate:date];
}

- (NSDate *)dateTime:(NSDate *)date timeString:(NSString *)timeString
{
	NSArray *fullTimeArr = [timeString componentsSeparatedByString:@" "];
	if (fullTimeArr.count > 0) {
		NSArray *timeArray = [fullTimeArr[0] componentsSeparatedByString:@":"];
		NSInteger hours = 0;
		NSInteger minutes = 0;
		
		if (timeArray.count > 0) {
			hours = [timeArray[0] integerValue];
		}
		
		if (timeArray.count > 1) {
			minutes = [timeArray[1] integerValue];
		}
		
		if (fullTimeArr.count > 1 && [fullTimeArr[1] length] > 0) {
			NSString *ampm = [fullTimeArr[1] substringToIndex:1];
			if ([[ampm uppercaseString] isEqualToString:@"P"] && hours < 12) {
				hours += 12;
			}
		}
		
		date = [date db_midnightDate];
		NSCalendar *cal = [NSCalendar currentCalendar];
		NSDateComponents *components = [cal components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:date];
		components.hour = hours;
		components.minute = minutes;
		
		return [cal dateByAddingComponents:components toDate:date options:0];
	}
	
	return nil;
}

- (void)didCloseParticipantListWindow:(DBBParticipantListWindowController *)participantListController
{
	[self.participantsTable reloadData];
	[self.window setIsVisible:YES];
	self.participantListWindowController = nil;
}

@end
