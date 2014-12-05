//
//  DBBProjectListWindowController.m
//  DBBuilder-Mac
//
//  Created by Dennis Birch on 11/20/14.
//  Copyright (c) 2014 Dennis Birch. All rights reserved.
//

#import "DBBProjectListWindowController.h"
#import "DBBEditProjectWindowController.h"
#import "DBBProject.h"

@interface DBBProjectListWindowController () <NSTableViewDataSource, NSTableViewDelegate, ProjectEditorDelegate>

@property (nonatomic, strong) DBBEditProjectWindowController *editWC;
@property (nonatomic, strong) NSArray *projects;
@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, strong) DBBProject *parentProject;

@end

@implementation DBBProjectListWindowController

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
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWindowActivationNotification:) name:NSWindowDidBecomeKeyNotification object:nil];
	
	[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleWindowWillCloseNotification:) name:NSWindowWillCloseNotification object:nil];

	[self loadProjects];
}

- (void)setupForSubprojectSelectionWithParentProject:(DBBProject *)parentProject
{
	self.parentProject = parentProject;
	[self loadProjects];
}

- (IBAction)plusButtonPushed:(id)sender
{
	self.editWC = [[DBBEditProjectWindowController alloc]initWithWindowNibName:@"DBBEditProjectWindowController"];
	self.editWC.delegate = self;
	[self.window setIsVisible:NO];
	[self.editWC showWindow:nil];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return (int)self.projects.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	DBBProject *project = self.projects[(unsigned)row];
	return project.name;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	NSInteger selected = [self.tableView selectedRow];
	if (selected < 0) {
		return;
	}
	DBBProject *project = self.projects[(unsigned)selected];
	
	if (self.parentProject != nil) {
		self.parentProject.subProject = project;
		[self.parentProject makeDirty];
		self.parentProject = nil;
	} else {
		self.editWC = [[DBBEditProjectWindowController alloc] initWithWindowNibName:@"DBBEditProjectWindowController"];
		self.editWC.delegate = self;
		self.editWC.project = project;
	}
	
	[self.window setIsVisible:NO];
	self.editWC.delegate = self;
	[self.editWC showWindow:nil];
}

- (void)loadProjects
{
	DBManager *mgr = [DBManager defaultDBManager];
	
	// select all projects, sorted by start date
	NSDictionary *queryOptions = @{kQuerySortingKey : @"startDate"};
	NSArray *result = [DBBProject objectsWithOptions:queryOptions manager:mgr];
	if (self.parentProject == nil) {
		self.projects = result;
	} else {
		NSMutableArray *temp = [NSMutableArray new];
		[result enumerateObjectsUsingBlock:^(DBBProject *project, NSUInteger idx, BOOL *stop) {
			if (![project isEqualTo:self.parentProject]) {
				[temp addObject:project];
			}
		}];
		self.projects = [temp copy];
	}

	[self.tableView reloadData];
}

- (void)closedProjectEditorWindow:(DBBEditProjectWindowController *)projectEditorWindow
{
	[self loadProjects];
}

- (void)handleWindowActivationNotification:(NSNotification *)notification
{
	[self.tableView deselectRow:[self.tableView selectedRow]];
}

- (void)handleWindowWillCloseNotification:(NSNotification *)notification
{
	static BOOL editWindClosed = false;
	
	if (!editWindClosed) {
		editWindClosed = YES;
		[self.editWC close];
		editWindClosed = NO;
	}
	
}

#pragma mark - Direct Database Query Example

- (IBAction)statisticsButtonClicked:(id)sender
{
    // this is a very simple example of sending queries directly to your database manager, just to show that you can
    NSMutableDictionary *countsDict = [NSMutableDictionary new];
    
    NSArray *queries = @[@"SELECT COUNT(id) As Projects FROM project",
                         @"SELECT COUNT(id) As Meetings FROM meeting",
                         @"SELECT COUNT(id) As Participants FROM person"];
    for (NSString *query in queries) {
        FMResultSet *results = [[DBManager defaultDBManager] runQuery:query];
        if (results != nil) {
            NSString *table = [results columnNameForIndex:0];
            NSInteger count = [results intForColumnIndex:0];
            countsDict[table] = @(count);
        }
    }
    
    NSString *message = @"Current counts for your Projects database:\n\n";
    for (NSString *table in [countsDict allKeys]) {
        message = [message stringByAppendingFormat:@"%@: %ld\n", table, (long)[countsDict[table] integerValue]];
    }
    
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText:@"Statistics"];
	[alert setInformativeText:message];
	[alert runModal];
}



@end
