//
//  DBBMeetingListViewController.m
//  DBBuilder
//
//  Created by Dennis Birch on 9/11/13.
//  Copyright (c) 2013 Dennis Birch. All rights reserved.
//

#import "DBBMeetingListViewController.h"
#import "DBBEditMeetingViewController.h"
#import "DBBMeeting.h"
#import "DBBProject.h"
#import "DBBPerson.h"
#import "NSString+DBExtensions.h"
#import <objc/runtime.h>


@interface DBBMeetingListViewController () <UITableViewDataSource, UITableViewDelegate, EditMeetingDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *meetings;
@property (nonatomic, strong) NSMutableArray *allMeetings;

@end

@implementation DBBMeetingListViewController

#define INDEX_PATH_KEY  @"INDEX_PATH_KEY"

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	self.title = @"Meetings";
	
	UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addMeeting:)];
	self.navigationItem.rightBarButtonItem = addButton;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	self.allMeetings = [[DBBMeeting allMeetings] mutableCopy];
	
	[self loadMeetings];
}


- (void)loadMeetings
{
	self.meetings = self.project.meetings;
	[self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (int)self.allMeetings.count;;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"MeetingCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	DBBMeeting *meeting = self.allMeetings[(unsigned)indexPath.row];
	cell.textLabel.text = meeting.purpose;
	
	// add a Pencil image user can click on to edit person
	UIImage *pencil = [UIImage imageNamed:@"Pencil"];
	cell.imageView.image = pencil;
	cell.imageView.userInteractionEnabled = YES;
	UITapGestureRecognizer *editTapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleEditTap:)];
	objc_setAssociatedObject(editTapper, INDEX_PATH_KEY, indexPath, OBJC_ASSOCIATION_RETAIN);
	[cell.imageView addGestureRecognizer:editTapper];

	// set checkmark for meetings belonging to project
	if ([self.project.meetings indexOfObject:meeting] == NSNotFound || self.project.meetings == nil) {
		cell.accessoryType = UITableViewCellAccessoryNone;
	} else {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	
	return cell;
}

- (void)handleEditTap:(UIGestureRecognizer *)gestureRecognizer
{
	NSIndexPath *indexPath = objc_getAssociatedObject(gestureRecognizer, INDEX_PATH_KEY);
	DBBMeeting *meeting = self.allMeetings[(unsigned)indexPath.row];
	[self performSegueWithIdentifier:@"EditMeetingSegue" sender:meeting];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
	// check off meetings included in project, and add or remove them depending on their state
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	DBBMeeting *meeting = self.allMeetings[(unsigned)indexPath.row];
	
	if (cell.accessoryType == UITableViewCellAccessoryNone) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
		[self.project addMeeting:meeting];
	} else {
		cell.accessoryType = UITableViewCellAccessoryNone;
		[self.project removeMeeting:meeting];
	}
	
	[self.project makeDirty];
}


- (IBAction)addMeeting:(id)sender
{
	[self performSegueWithIdentifier:@"AddMeetingSegue" sender:nil];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    DBBEditMeetingViewController *vc = segue.destinationViewController;

    if ([segue.identifier isEqualToString:@"EditMeetingSegue"]) {
		DBBMeeting *meeting;
		if ([sender isKindOfClass:[DBBMeeting class]]) {
			meeting = sender;
		}

		vc.meeting = meeting;
		vc.title = @"Edit Meeting";
		vc.delegate = nil;
	}
    
    else if ([segue.identifier isEqualToString:@"AddMeetingSegue"]) {
        DBBMeeting *meeting = [DBBMeeting new];
        meeting.startTimeActual = [NSDate date];
        meeting.finishTimeActual = [NSDate date];
        vc.meeting = meeting;
		vc.title = @"Add Meeting";
		vc.delegate = self;
    }
}

#pragma mark - EditMeetingDelegate

- (void)meetingEditor:(DBBEditMeetingViewController *)meetingEditor savedMeeting:(DBBMeeting *)meeting
{
	[self.project addMeeting:meeting];
}

@end
