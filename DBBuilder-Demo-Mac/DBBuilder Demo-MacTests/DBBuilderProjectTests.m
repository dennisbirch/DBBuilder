//
//  DBBuilderProjectTests.m
//  DBBuilder
//
//  Created by Dennis Birch on 9/19/13.
//  Copyright (c) 2013 Dennis Birch. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "DBManager.h"
#import "FMDatabase.h"
#import "DBBProject.h"
#import "DBBPerson.h"
#import "AppDelegate.h"
#import "CommonSetup.h"
#import "NSString+DBExtensions.h"

@interface DBBuilderProjectTests : XCTestCase <NSFileManagerDelegate>

@property (nonatomic, strong) DBManager *manager;
@property (nonatomic, assign) NSInteger lastProjectID;

@end

@implementation DBBuilderProjectTests

- (void)setUp
{
    [super setUp];
	
	CommonSetup *setup = [[CommonSetup alloc] init];
	[setup performSetUp];
	
	self.manager = setup.manager;
}

- (void)tearDown
{
    CommonSetup *setup = [[CommonSetup alloc] init];
    [setup performTeardown];
    
    [super tearDown];
}

- (void)testCreateProject
{
    DBBProject *proj = [[DBBProject alloc] initWithManager:self.manager];
	proj.name = @"Subproject";
	proj.code = @"12345";
	proj.startDate = [NSDate date];
	   
    XCTAssertNotNil(proj, @"proj should not be nil in testCreateProject");
	
	BOOL success = [proj saveToDB];
	XCTAssertTrue(success, @"Saving a project to the database should return true in testCreateProject");
	
	// create a parent project with proj as subproject
	DBBProject *parentProj = [[DBBProject alloc] initWithManager:self.manager];
	parentProj.name = @"Parent project";
	parentProj.code = @"ABCDEF";
	parentProj.startDate = [NSDate date];
	parentProj.subProject = proj;
	parentProj.budget = [NSDecimalNumber decimalNumberWithString:@"4321.00"];
    
    XCTAssertNotNil(parentProj, @"parentProj should not be nil in testCreateProject");
    
    // add a project lead
    DBBPerson *lead = [[DBBPerson alloc] initWithManager:self.manager];
    lead.firstName = @"Michael";
    lead.lastName = @"Manager";
    lead.department = @"Management";
    success = [lead saveToDB];
    XCTAssertTrue(success, @"Saving a person should succeed in %s", __PRETTY_FUNCTION__);
    
    parentProj.projectLead = lead;
                
	success = [parentProj saveToDB];
	XCTAssertTrue(success, @"Saving parentProj to the database should return true in %s", __PRETTY_FUNCTION__);
	
	// valid project IDs
	NSInteger projectID = proj.itemID;
	XCTAssertTrue(projectID > 0, @"proj ID should be greater than 0 in %s", __PRETTY_FUNCTION__);
	
	self.lastProjectID = parentProj.itemID;
	XCTAssertTrue(self.lastProjectID > projectID, @"parent project's ID should be higher than sub-project's ID in %s", __PRETTY_FUNCTION__);

	// fetch project from table

	proj = [[DBBProject alloc] initWithID:self.lastProjectID manager:self.manager];

	XCTAssertNotNil(proj, @"Fetching the parent Project by its ID should not return nil");
	
	XCTAssertTrue([proj.name isEqualToString:@"Parent project"], @"Parent project's name should be \"Parent project\" %s", __PRETTY_FUNCTION__);
	XCTAssertTrue([proj.code isEqualToString:@"ABCDEF"], @"Parent project's code should be \"ABCDEF\" %s", __PRETTY_FUNCTION__);
	XCTAssertTrue([proj.startDate isKindOfClass:[NSDate class]], @"Parent project's start date should be an NSDate in %s", __PRETTY_FUNCTION__);
	XCTAssertNotNil(proj.subProject, @"Parent project's subproject should not be nil in %s", __PRETTY_FUNCTION__);
    DBBPerson *projLead = proj.projectLead;
    XCTAssertNotNil(projLead, @"Project lead should not be nil in %s",__PRETTY_FUNCTION__);
    XCTAssertTrue([projLead.lastName isEqualToString:@"Manager"], @"Project lead's last name should be 'Manager' in %s", __PRETTY_FUNCTION__);
	
	proj = proj.subProject;

	// check subproject properties/class
	XCTAssertTrue([proj.name isEqualToString:@"Subproject"], @"Child project's name should be \"Subproject\" in testCreateProject");
	XCTAssertTrue([proj.code isEqualToString:@"12345"], @"Child project's code should be \"12345\" in testCreateProject");
	XCTAssertTrue([proj.startDate isKindOfClass:[NSDate class]], @"Child project's start date should be an NSDate in testCreateProject");
	XCTAssertNil(proj.subProject, @"Child project's subproject should be nil in testCreateProject");
    
    // exercise data object accessor method(s)
    NSArray *conditions = @[@"name = Subproject"];
	NSDictionary *options = @{kQueryConditionsKey : conditions};
    NSArray *results = [DBBProject objectsWithOptions:options manager:self.manager];
    XCTAssertNotNil(results, @"Results dictionary should not be nil in testCreateProject");
    
    DBBProject *instance = [results lastObject];
    Class c = [DBBProject class];
    XCTAssertTrue([instance isKindOfClass:c], @"Results array's last object should be a %@ instead of a %@ in testCreateProject", c, [instance class]);
    
    NSArray *columns = @[@"name", @"code"];
	options = @{kQueryColumnsKey : columns,
				kQueryConditionsKey : conditions};
    results = [DBBProject objectsWithOptions:options manager:self.manager];
    instance = results.firstObject;
 
    NSString *value = instance.code;
    XCTAssertTrue([value isEqualToString:@"12345"], @"Subproject instance's code should be \"12345\" instead of %@ in testCreateProject", value);
    
    value = instance.name;
    XCTAssertTrue([value isEqualToString:@"Subproject"], @"Subproject instance's name should be \"Subproject\" instade of %@ in testCreateProject", value);
    
    XCTAssertNil(instance.startDate, @"Subproject instance's startTime should be nil in testCreateProject");
}

- (void)testSavedInstanceWithValues
{
	NSDictionary *values = @{@"name" : @"Auto-saved project",
							 @"code" : @"CODE-blue",
							 @"startDate" : [NSDate date],
							 @"endDate" : [NSDate date]
							 };
	DBBProject *classProject = [DBBProject savedInstanceWithValues:values manager:self.manager];
	XCTAssertNotNil(classProject, @"ClassProject should not be nil in %s", __PRETTY_FUNCTION__);
	
	NSDictionary *options = @{kQueryConditionsKey : [NSString stringWithFormat:@"id=%ld",(long)classProject.itemID]};
	NSArray *results = [DBBProject objectsWithOptions:options manager:self.manager];
	DBBProject *copyProject = [results lastObject];
	XCTAssertNotNil(copyProject, @"CopyProject should not be nil in %s", __PRETTY_FUNCTION__);
	
	XCTAssertTrue(classProject.itemID > 0, @"Class project's ID should be greater than 0 in %s", __PRETTY_FUNCTION__);
	
	XCTAssertEqual(classProject.itemID, copyProject.itemID, @"ID of classProject and copyProject should be the same in %s", __PRETTY_FUNCTION__);
	
	XCTAssertEqualObjects(classProject.name, copyProject.name, @"ClassProject name and CopyProject name should be the same in %s", __PRETTY_FUNCTION__);

	XCTAssertEqualObjects(classProject.code, copyProject.code, @"ClassProject code and CopyProject code should be the same in %s", __PRETTY_FUNCTION__);

	XCTAssertEqualObjects(classProject.startDate.description, copyProject.startDate.description, @"ClassProject start date and CopyProject start date should be the same in %s", __PRETTY_FUNCTION__);
	
	// test passing a bad property key
	values = @{@"name" : @"Another auto-saved project",
				@"clode" : @"CODE-blue",
				@"startDate" : [NSDate date],
				@"endDate" : [NSDate date]
				};
	DBBProject *anotherProject = [DBBProject savedInstanceWithValues:values manager:self.manager];
	XCTAssertNotNil(anotherProject, @"Another project should not be nil in %s", __PRETTY_FUNCTION__);
	
	XCTAssertNil(anotherProject.code, @"Another project's code should be nil in %s", __PRETTY_FUNCTION__);
	XCTAssertNotNil(anotherProject.name, @"Another project's name should not be nil in %s", __PRETTY_FUNCTION__);
}


- (void)testProjectUpdating
{
#define kParentProjectName	@"Update parent project"
#define kParentProjectCode	@"ABCDEF"
    NSDecimalNumber *kParentProjectBudget = [NSDecimalNumber decimalNumberWithString:@"4321.17"];
    NSDate *kParentProjectStartDate = [NSDate date];
#define kSubProjectName		@"Update Subproject";
#define kSubProjectCode		@"12345";
    NSDate *kSubProjectStartDate = [NSDate date];
    
    // create a parent project with proj as subproject
    DBBProject *parentProj = [[DBBProject alloc] initWithManager:self.manager];
    XCTAssertNotNil(parentProj, @"Update Parent proj should not be nil in %s", __PRETTY_FUNCTION__);
    parentProj.name = kParentProjectName;
    
    BOOL success = [parentProj saveToDB];
    XCTAssertTrue(success, @"Saving Update parent project should return true in %s",__PRETTY_FUNCTION__);
    
    NSInteger projectID = parentProj.itemID;
    XCTAssertTrue(projectID > 0, @"Update parent project's ID should be greater than 0 in %s", __PRETTY_FUNCTION__);
    
    parentProj.code = kParentProjectCode;
    parentProj.startDate = kParentProjectStartDate;
    parentProj.budget = kParentProjectBudget;
    
    success = [parentProj saveToDB];
    XCTAssertTrue(success, @"Saving Update parent project a second time should return true in %s", __PRETTY_FUNCTION__);
    XCTAssertEqual(parentProj.itemID, projectID, @"Update parent project's ID should equal %ld after second save in %s", (long)projectID, __PRETTY_FUNCTION__);
    
    DBBProject *subProj = [[DBBProject alloc] initWithManager:self.manager];
    subProj.name = kSubProjectName;
    XCTAssertNotNil(subProj, @"Update subproject should not be nil in %s", __PRETTY_FUNCTION__);
    
    success = [subProj saveToDB];
    XCTAssertTrue(success, @"Saving Update subproject should return true in %s", __PRETTY_FUNCTION__);
    
    NSInteger subID = subProj.itemID;
    
    subProj.code = kSubProjectCode;
    subProj.startDate = kSubProjectStartDate;
    success = [subProj saveToDB];
    XCTAssertEqual(subProj.itemID, subID, @"Update subproject's ID should equal %ld after second save in %s", (long)subID, __PRETTY_FUNCTION__);
	   
    parentProj.subProject = subProj;
    success = [parentProj saveToDB];
    
    XCTAssertTrue(success, @"Saving parent project third time should return true in %s", __PRETTY_FUNCTION__);
    
    NSString *conditions = [NSString stringWithFormat:@"id = %ld", (long)projectID];
    NSDictionary *options = @{kQueryConditionsKey : conditions};

    // test queued fetch
    [DBBProject queueObjectsWithOptions:options manager:self.manager completionBlock:^(NSArray *resultsArray, NSError *error) {
        DBBProject *fetchedProject = [resultsArray lastObject];
        XCTAssertEqual(fetchedProject.itemID, projectID, @"Fetched project's ID should be %ld in %s", (long)projectID, __PRETTY_FUNCTION__);
        XCTAssertNotNil(fetchedProject.subProject, @"Fetched project's subproject should not be nil in %s", __PRETTY_FUNCTION__);
        XCTAssertEqualObjects(fetchedProject.code, kParentProjectCode, @"Fetched project's code should be %@ in %s", kParentProjectCode, __PRETTY_FUNCTION__);
        XCTAssertEqualObjects(fetchedProject.name, kParentProjectName, @"Fetched project's code should be %@ in %s", kParentProjectName, __PRETTY_FUNCTION__);
        XCTAssertEqualObjects(fetchedProject.budget, kParentProjectBudget, @"Fetched project's budget should be %@ in %s", kParentProjectBudget, __PRETTY_FUNCTION__);
        XCTAssertEqual(fetchedProject.subProject.itemID, subID, @"ID of fetched project's subproject should be %ld in %s", (long)subID, __PRETTY_FUNCTION__);
        
        NSString *string = kSubProjectName;
        XCTAssertEqualObjects(fetchedProject.subProject.name, string, @"Name of fetched project's subproject should be %@ in %s", string, __PRETTY_FUNCTION__);
        string = kSubProjectCode;
        XCTAssertEqualObjects(fetchedProject.subProject.code, string, @"Code of fetched project's subproject should be %@ in %s", string, __PRETTY_FUNCTION__);
    }];
}

@end
