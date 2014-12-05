//
//  DBBEditPersonWindowController.m
//  DBBuilder Demo-Mac
//
//  Created by Dennis Birch on 11/28/14.
//  Copyright (c) 2014 Dennis Birch. All rights reserved.
//

#import "DBBEditPersonWindowController.h"
#import "DBBPerson.h"

@interface DBBEditPersonWindowController () <NSTextFieldDelegate>

@property (nonatomic, weak) IBOutlet NSTextField *firstNameField;
@property (nonatomic, weak) IBOutlet NSTextField *middleInitialField;
@property (nonatomic, weak) IBOutlet NSTextField *lastNameField;
@property (nonatomic, weak) IBOutlet NSTextField *departementField;
@property (nonatomic, weak) IBOutlet NSButton *saveButton;

@property (nonatomic, strong) NSTextField *activeTextField;

@end

@implementation DBBEditPersonWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
	[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleTextChangedNotification:) name:NSControlTextDidChangeNotification object:nil];
	
	if (self.participant == nil) {
		self.window.title = @"Add Participant";
		self.participant = [[DBBPerson alloc] initWithManager:[DBManager defaultDBManager]];
	} else {
		self.window.title = @"Edit Participant";
		self.firstNameField.stringValue = self.participant.firstName;
		self.middleInitialField.stringValue = self.participant.middleInitial;
		self.lastNameField.stringValue = self.participant.lastName;
		self.departementField.stringValue = self.participant.department;
	}
	
	[self enableSaveButton];
	self.firstNameField.delegate = self;
	self.middleInitialField.delegate = self;
	self.lastNameField.delegate = self;
	self.departementField.delegate = self;
}


- (void)enableSaveButton
{
	[self.saveButton setEnabled:(self.firstNameField.stringValue.length > 0 && self.lastNameField.stringValue.length > 0 && self.departementField.stringValue.length > 0)];
}


- (IBAction)saveChanges:(id)sender
{
	[self.participant saveToDB];
	[self cancelClose:nil];
}

- (IBAction)cancelClose:(id)sender
{
	[self.window close];
	[self.delegate didCloseEditPersonWindow:self];
}

- (void)handleTextChangedNotification:(NSNotification *)notification
{
	if (self.activeTextField == self.firstNameField) {
		self.participant.firstName = self.firstNameField.stringValue;
	} else if (self.activeTextField == self.middleInitialField) {
		self.participant.middleInitial = [self.middleInitialField.stringValue substringToIndex:1];
	} else if (self.activeTextField == self.lastNameField) {
		self.participant.lastName = self.lastNameField.stringValue;
	} else if (self.activeTextField == self.departementField) {
		self.participant.department = self.departementField.stringValue;
	}
	
	[self.participant makeDirty];
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


@end
