//
//  DBBParticipantListWindowController.m
//  DBBuilder Demo-Mac
//
//  Created by Dennis Birch on 11/27/14.
//  Copyright (c) 2014 Dennis Birch. All rights reserved.
//

#import "DBBParticipantListWindowController.h"
#import "DBBEditPersonWindowController.h"
#import "DBBPerson.h"
#import "DBBMeeting.h"

@interface DBBParticipantListWindowController () <NSTableViewDataSource, NSTableViewDelegate, EditPersonDelegate>

@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, weak) IBOutlet NSTableColumn *editColumn;
@property (nonatomic, weak) IBOutlet NSTableColumn *checkColumn;
@property (nonatomic, weak) IBOutlet NSTableColumn *nameColumn;
@property (nonatomic, weak) IBOutlet NSButton *createNewMeetingButton;

@property (nonatomic, strong) NSArray *allParticipants;

@property (nonatomic, strong) DBBEditPersonWindowController *editPersonController;

@end

@implementation DBBParticipantListWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
	
	self.tableView.rowHeight = 24;
	[self loadParticipants];
}

- (void)loadParticipants
{
	DBManager *mgr = [DBManager defaultDBManager];
	
	// select all projects, sorted by start date
	NSDictionary *queryOptions = @{kQuerySortingKey : @"lastName"};
	NSArray *result = [DBBPerson objectsWithOptions:queryOptions manager:mgr];
	self.allParticipants = result;

	[self.tableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return (unsigned)self.allParticipants.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	DBBPerson *person = self.allParticipants[(unsigned)row];
	NSView *view;
	
	if (tableColumn == self.editColumn) {
		NSButton *pencilBtn = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
		[pencilBtn setImage:[NSImage imageNamed:@"Pencil"]];
		pencilBtn.tag = row;
		pencilBtn.showsBorderOnlyWhileMouseInside = YES;
		[pencilBtn setTarget:self];
		[pencilBtn setAction:@selector(editPersonForButton:)];
		view = pencilBtn;
		
	} else if (tableColumn == self.checkColumn) {
		NSButton *check = [[NSButton alloc] init];
		check.tag = row;
		[check setButtonType:NSSwitchButton];
		[check setState:self.meeting.participants != nil &&
			[self.meeting.participants indexOfObject:person] != NSNotFound];
		[check setTarget:self];
		[check setAction:@selector(handleCheckboxClick:)];
		view = check;
	} else if (tableColumn == self.nameColumn) {
		NSTextField *nameLabel = [[NSTextField alloc] initWithFrame:CGRectMake(0, 0, 300, 22)];;
		[nameLabel setStringValue:[person fullNameAndDepartment]];
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
	DBBPerson *person = self.allParticipants[(unsigned)tag];
	if (state) {
		[self.meeting addParticipant:person];
	} else {
		[self.meeting removeParticipant:person];
	}
	
	[self.meeting makeDirty];
}

- (void)editPersonForButton:(NSButton *)button
{
	NSInteger row = button.tag;
	DBBPerson *person = self.meeting.participants[(unsigned)row];
	self.editPersonController = [[DBBEditPersonWindowController alloc] initWithWindowNibName:@"DBBEditPersonWindowController"];
	self.editPersonController.delegate = self;
	self.editPersonController.participant = person;
	[self.window setIsVisible:NO];
	[self.editPersonController showWindow:nil];
}

- (IBAction)makeNewParticipant:(id)sender
{
	self.editPersonController = [[DBBEditPersonWindowController alloc] initWithWindowNibName:@"DBBEditPersonWindowController"];
	self.editPersonController.delegate = self;
	[self.window setIsVisible:NO];
	[self.editPersonController showWindow:nil];
}

- (void)didCloseEditPersonWindow:(DBBEditPersonWindowController *)editPersonController
{
	[self.window setIsVisible:YES];
	self.editPersonController = nil;
	[self loadParticipants];
}

- (IBAction)saveChanges:(id)sender
{
	[self.meeting saveToDB];
	[self cancelClose:nil];
}

- (IBAction)cancelClose:(id)sender
{
	[self.window close];
	[self.delegate didCloseParticipantListWindow:self];
}



@end
