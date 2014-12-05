//
//  DBBMeetingListController.m
//  DBBuilder Demo-Mac
//
//  Created by Dennis Birch on 11/22/14.
//  Copyright (c) 2014 Dennis Birch. All rights reserved.
//

#import "DBBMeetingListController.h"
#import "DBBEditMeetingWindowController.h"
#import "DBManager.h"
#import "DBBProject.h"
#import "DBBMeeting.h"

@interface DBBMeetingListController () <NSTableViewDataSource, NSTableViewDelegate, MeetingEditorDelegate>

@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, weak) IBOutlet NSTableColumn *editColumn;
@property (nonatomic, weak) IBOutlet NSTableColumn *checkColumn;
@property (nonatomic, weak) IBOutlet NSTableColumn *nameColumn;
@property (nonatomic, weak) IBOutlet NSButton *createNewMeetingButton;

@property (nonatomic, strong) DBBEditMeetingWindowController *editMeetingController;
@property (nonatomic, strong) NSArray *allMeetings;

@end

@implementation DBBMeetingListController

- (void)windowDidLoad {
    [super windowDidLoad];
	
	self.tableView.rowHeight = 24;
	[self loadMeetings];
}


- (void)loadMeetings
{
	DBManager *mgr = [DBManager defaultDBManager];
	
	// select all projects, sorted by start date
	NSDictionary *queryOptions = @{kQuerySortingKey : @"startTimeActual"};
	NSArray *result = [DBBMeeting objectsWithOptions:queryOptions manager:mgr];
	self.allMeetings = result;
	
	[self.tableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return (int)self.allMeetings.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	DBBMeeting *meeting = self.allMeetings[(unsigned)row];
	NSView *view;
	
	if (tableColumn == self.editColumn) {
		NSButton *pencilBtn = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
		[pencilBtn setImage:[NSImage imageNamed:@"Pencil"]];
		pencilBtn.tag = row;
		pencilBtn.showsBorderOnlyWhileMouseInside = YES;
		[pencilBtn setTarget:self];
		[pencilBtn setAction:@selector(editMeetingForButton:)];
		view = pencilBtn;
		
	} else if (tableColumn == self.checkColumn) {
		NSButton *check = [[NSButton alloc] init];
		check.tag = row;
		[check setButtonType:NSSwitchButton];
		[check setState:self.project.meetings != nil &&
			[self.project.meetings indexOfObject:meeting] != NSNotFound];
		[check setTarget:self];
		[check setAction:@selector(handleCheckboxClick:)];
		view = check;
	} else if (tableColumn == self.nameColumn) {
		NSTextField *nameLabel = [[NSTextField alloc] initWithFrame:CGRectMake(0, 0, 300, 22)];
		[nameLabel setStringValue:meeting.purpose];
		[nameLabel setEditable:NO];
		view = nameLabel;
	}
	
	return view;
}

- (void)handleCheckboxClick:(id)sender
{
	NSButton *check = sender;
	NSInteger tag = check.tag;
	BOOL state = (BOOL)check.state;
	DBBMeeting *meeting;
	if ((int)self.allMeetings.count > tag) {
		meeting = self.allMeetings[(unsigned)tag];
	}
	if (state && meeting != nil) {
		[self.project addMeeting:meeting];
	} else if (meeting!= nil) {
		[self.project removeMeeting:meeting];
	}
	
	[self.project makeDirty];
}

- (void)editMeetingForButton:(NSButton *)button
{
	NSInteger row = button.tag;
	DBBMeeting *meeting = self.project.meetings[(unsigned)row];
	self.editMeetingController = [[DBBEditMeetingWindowController alloc] initWithWindowNibName:@"DBBEditMeetingWindowController"];
	self.editMeetingController.delegate = self;
	self.editMeetingController.meeting = meeting;
	[self.editMeetingController showWindow:nil];
	[self.window setIsVisible:NO];
}

- (IBAction)makeNewMeeting:(id)sender
{
	self.editMeetingController = [[DBBEditMeetingWindowController alloc] initWithWindowNibName:@"DBBEditMeetingWindowController"];
	self.editMeetingController.delegate = self;
	[self.editMeetingController showWindow:nil];
	[self.window setIsVisible:NO];
}

- (void)didCloseMeetingEditor:(DBBEditMeetingWindowController *)meetingEditor
{
	[self.window setIsVisible:YES];
	self.editMeetingController = nil;
	[self loadMeetings];
}

- (IBAction)saveChanges:(id)sender
{
	[self.project saveToDB];
	[self cancelClose:nil];
}

- (IBAction)cancelClose:(id)sender
{
	[self.window close];
	[self.delegate didCloseMeetingListWindow:self];
}


@end


