//
//  DBBEditAttendeesTableViewController.m
//  DBBuilder
//
//  Created by Dennis Birch on 11/5/14.
//  Copyright (c) 2014 Dennis Birch. All rights reserved.
//

#import "DBBEditAttendeesTableViewController.h"
#import "DBBEditPersonView.h"
#import "DBBMeeting.h"
#import "DBBPerson.h"
#import <objc/runtime.h>
#import	"DBMacros.h"


@interface DBBEditAttendeesTableViewController ()

@property (nonatomic, strong) UIView *participantEditView;
@property (nonatomic, strong) DBBPerson *editedParticipant;
@property (nonatomic, assign) BOOL isNewParticipantFlag;

@property (nonatomic, strong) NSMutableArray *allPeople;

@end

@implementation DBBEditAttendeesTableViewController

#define INDEX_PATH_KEY  @"INDEX_PATH_KEY"

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addParticipant)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    self.allPeople = [[DBBPerson allPeople] mutableCopy];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return (int)self.allPeople.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    DBBPerson *person = self.allPeople[(unsigned)indexPath.row];
    cell.textLabel.text = person.fullNameAndDepartment;
    
    // add a Pencil image user can click on to edit person
    UIImage *pencil = [UIImage imageNamed:@"Pencil"];
    cell.imageView.image = pencil;
    cell.imageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *editTapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleEditTap:)];
    objc_setAssociatedObject(editTapper, INDEX_PATH_KEY, indexPath, OBJC_ASSOCIATION_RETAIN);
    [cell.imageView addGestureRecognizer:editTapper];
    
    if ([self.meeting.participants indexOfObject:person] == NSNotFound || self.meeting.participants == nil) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    return cell;
}

- (void)handleEditTap:(UIGestureRecognizer *)gestureRecognizer
{
    NSIndexPath *indexPath = objc_getAssociatedObject(gestureRecognizer, INDEX_PATH_KEY);
    DBBPerson *person = self.allPeople[(unsigned)indexPath.row];
    self.editedParticipant = person;
    [self showEditViewForPerson:person];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // check off people included in meeting, and add or remove them depending on their state
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    DBBPerson *person = self.allPeople[(unsigned)indexPath.row];
    if (cell.accessoryType == UITableViewCellAccessoryNone) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [self.meeting addParticipant:person];
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        [self.meeting removeParticipant:person];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
	
	[self.meeting makeDirty];
}

#pragma mark - Editing Participants

- (void)addParticipant
{
    DBBPerson *newPerson = [DBBPerson new];
    self.isNewParticipantFlag = YES;
    [self showEditViewForPerson:newPerson];
}


- (void)showEditViewForPerson:(DBBPerson *)person
{
	self.editedParticipant = person;
	
	DBBEditPersonView *view = [[DBBEditPersonView alloc] initWithFrame:self.view.frame
																person:person
															saveAction:^void(DBBPerson *editPerson) {
																if (editPerson.isDirty) {
																	[self saveEditPerson:editPerson];
																}
															}
														  cancelAction:^void(){
															  [self endEditPerson];
														  }];
	
	self.participantEditView = view;
	view.alpha = 0;
	
	[self.view.window addSubview:view];
	
	[UIView animateWithDuration:.25 animations:^{
		view.alpha = 1.0;
	}];
}

- (void)endEditPerson
{
    [UIView animateWithDuration:.25 animations:^{
        self.participantEditView.alpha = 0;
    }];
	
    [self.participantEditView removeFromSuperview];
    self.participantEditView = nil;
    self.isNewParticipantFlag = NO;
}

- (void)saveEditPerson:(DBBPerson *)person
{
    BOOL success = [person saveToDB];
	
    if (success && self.isNewParticipantFlag) {
        if ([self.allPeople indexOfObject:person] == NSNotFound) {
            [self.allPeople addObject:person];
        }
    }
    
    [self endEditPerson];
    [self.tableView reloadData];
}

@end
