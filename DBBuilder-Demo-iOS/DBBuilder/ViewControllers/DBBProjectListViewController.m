//
//  DBBProjectListViewController.m
//  DBBuilder
//
//  Created by Dennis Birch on 11/10/14.
//  Copyright (c) 2014 Dennis Birch. All rights reserved.
//

#import "DBBProjectListViewController.h"
#import "DBBEditProjectViewController.h"
#import "DBManager.h"
#import "FMDatabase.h"
#import "DBBProject.h"
#import "FMDatabase.h"

@interface DBBProjectListViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIButton *statsButton;
@property (nonatomic, copy) NSArray *projects;

@end

@implementation DBBProjectListViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	
	UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                               target:self
                                                                               action:@selector(addProject:)];
	self.navigationItem.rightBarButtonItem = addButton;
    self.title = @"Projects";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self loadProjects];
    
    // set up for selecting sub-project
    if (self.parentProject != nil) {
        self.tableView.contentInset = UIEdgeInsetsMake(44.0, 0, 0, 0);
        self.statsButton.hidden = YES;
        [self addCancelButton];
        NSMutableArray *temp = [NSMutableArray new];
        [self.projects enumerateObjectsUsingBlock:^(DBBProject *obj, NSUInteger idx, BOOL *stop) {
            if (obj.itemID != self.parentProject.itemID)
                [temp addObject:obj];
        }];
        self.projects = [temp copy];
        [self.tableView reloadData];
    }
}

- (void)addCancelButton
{
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    cancelButton.frame = CGRectMake(12.0f, 12.0f, 60.0f, 32.0f);
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(handleCancelTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cancelButton];
}

- (void)handleCancelTap
{
    self.parentProject.subProject = nil;
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	DBBEditProjectViewController *vc = segue.destinationViewController;
    vc.title = @"Add Project";

	if ([segue.identifier isEqualToString:@"EditProjectSegue"]) {
		NSIndexPath *path = [self.tableView indexPathForSelectedRow];
		DBBProject *project = self.projects[(unsigned)path.row];
        vc.title = @"Edit Project";
		vc.project = project;
	}
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"EditProjectSegue"]) {
        return self.parentProject == nil;
    }
    
    return YES;
}

- (void)loadProjects
{
	DBManager *mgr = [DBManager defaultDBManager];
	
	// select all meetings, sorted by start date
	NSDictionary *queryOptions = @{kQuerySortingKey : @"startDate"};
	NSArray *result = [DBBProject objectsWithOptions:queryOptions manager:mgr];
	self.projects = result;
	[self.tableView reloadData];
}

- (void)addProject:(id)sender
{
	[self performSegueWithIdentifier:@"AddProjectSegue" sender:self];
}

- (IBAction)statisticsButtonTapped:(id)sender
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
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Statistics"
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return (int)self.projects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	DBBProject *project = self.projects[(unsigned)indexPath.row];
	cell.textLabel.text = project.name;

    if (self.parentProject != nil) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

	return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.parentProject != nil) {
        DBBProject *project = self.projects[(unsigned)indexPath.row];
        self.parentProject.subProject = project;
        [self.parentProject makeDirty];
        [self dismissViewControllerAnimated:YES completion:^{
            //
        }];
    }
}

@end
