//
//  DBBMeetingTests.m
//  DBBuilder
//
//  Created by Dennis Birch on 9/23/13.
//  Copyright (c) 2013 Dennis Birch. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "DBManager.h"
#import "FMDatabase.h"
#import "DBBProject.h"
#import "DBBMeeting.h"
#import "DBBPerson.h"
#import "AppDelegate.h"
#import "DBTableRepresentation.h"
#import "CommonSetup.h"

@interface DBBMeetingTests : XCTestCase

@property (nonatomic, strong) DBManager *manager;

@end

@implementation DBBMeetingTests

- (void)setUp
{
    [super setUp];
    
	CommonSetup *setup = [[CommonSetup alloc] init];
	[setup performSetUp];
	
	self.manager = setup.manager;
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testMeeting
{
	DBBMeeting *mtg = [[DBBMeeting alloc] initWithManager:self.manager];
	mtg.purpose = @"Choose new hiree";
	mtg.startTimeActual = [NSDate date];
	mtg.scheduledHours = .75;
	
	DBBPerson *p1 = [[DBBPerson alloc] initWithManager:self.manager];
	p1.firstName = @"Dennis";
	p1.lastName = @"Birch";
	p1.department = @"Engineering";

	DBBPerson *p2 = [[DBBPerson alloc] initWithManager:self.manager];
	p2.firstName = @"Simon";
	p2.lastName = @"Sez";
	p2.department = @"Management";
	BOOL success = [p1 saveToDB];
	XCTAssertTrue(success, @"Person 1 should be saved successfully in %s", __PRETTY_FUNCTION__);
	success = [p2 saveToDB];
	XCTAssertTrue(success, @"Person 2 should be saved successfully in %s", __PRETTY_FUNCTION__);
	
	mtg.participants = @[p1, p2];
	success = [mtg saveToDB];
	
	
	XCTAssertTrue(success, @"Meeting should be saved successfully in %s", __PRETTY_FUNCTION__);
	NSInteger mtgID = mtg.itemID;

	NSDictionary *options = @{kQueryConditionsKey : [NSString stringWithFormat:@"id = %ld", (long)mtgID]};
    NSArray *result = [DBBMeeting objectsWithOptions:options manager:self.manager];
    DBBMeeting *newMtg = [result lastObject];
    newMtg.participants = @[p1, p2];
	XCTAssertEqualObjects(newMtg.purpose, @"Choose new hiree", @"New meeting purpose should be \"Choose new hiree\" in %s", __PRETTY_FUNCTION__);
	XCTAssertEqual(newMtg.scheduledHours, .75, @"New meeting scheduledHours should be .75 in %s", __PRETTY_FUNCTION__);
    NSUInteger expectedCount = 2;
	XCTAssertEqual(newMtg.participants.count, expectedCount, @"New meeting should have two participants in %s", __PRETTY_FUNCTION__);
	DBBPerson *lastPerson = [newMtg.participants lastObject];
	XCTAssertEqualObjects(lastPerson.firstName, @"Simon", @"The last participant's first name should be \"Simon\" in %s", __PRETTY_FUNCTION__);
	
	// object deletion
	NSInteger itemID = lastPerson.itemID;
	[DBBPerson deleteObject:lastPerson];
	
	DBBPerson *deletedPerson = [[DBBPerson alloc] initWithID:itemID manager:self.manager];
	XCTAssertNil(deletedPerson, @"The person deleted should be nil in %s", __PRETTY_FUNCTION__);
    
    // test deleting multiple objects
    p1 = [[DBBPerson alloc] initWithManager:self.manager];
    p1.firstName = @"Joe";
    p1.lastName = @"Schmoe";
    p1.department = @"Support";
    
    p2 = [[DBBPerson alloc] initWithManager:self.manager];
    p2.firstName = @"Sally";
    p2.lastName = @"Smith";
    p2.department = @"Marketing";
    
    success = [p1 saveToDB];
    XCTAssertTrue(success, @"Person 1 should be saved successfully in %s", __PRETTY_FUNCTION__);
    
    success = [p2 saveToDB];
    XCTAssertTrue(success, @"Person 2 should be saved successfully in %s", __PRETTY_FUNCTION__);
    
    
}

- (void)testMultipleObjectDeletion
{
    DBBMeeting *mtg1 = [[DBBMeeting alloc] initWithManager:self.manager];
    mtg1.purpose = @"Choose new hiree";
    mtg1.startTimeActual = [NSDate date];
    mtg1.scheduledHours = .75;
    
    DBBPerson *p1 = [[DBBPerson alloc] initWithManager:self.manager];
    p1.firstName = @"Dennis";
    p1.lastName = @"Birch";
    p1.department = @"Engineering";
    
    DBBPerson *p2 = [[DBBPerson alloc] initWithManager:self.manager];
    p2.firstName = @"Simon";
    p2.lastName = @"Sez";
    p2.department = @"Management";
    BOOL success = [p1 saveToDB];
    XCTAssertTrue(success, @"Person 1 should be saved successfully in %s", __PRETTY_FUNCTION__);
    success = [p2 saveToDB];
    XCTAssertTrue(success, @"Person 2 should be saved successfully in %s", __PRETTY_FUNCTION__);
    
    mtg1.participants = @[p1, p2];
    success = [mtg1 saveToDB];
	XCTAssertTrue(success, @"Meeting should be saved successfully in %s", __PRETTY_FUNCTION__);
    
	NSInteger mtgID = mtg1.itemID;
	NSDictionary *options = @{kQueryConditionsKey : [NSString stringWithFormat:@"id = %ld",(long)mtgID]};
    NSArray *result = [DBBMeeting objectsWithOptions:options manager:self.manager];
    DBBMeeting *newMtg = [result lastObject];
    newMtg.participants = @[p1, p2];
    XCTAssertEqualObjects(newMtg.purpose, @"Choose new hiree", @"New meeting purpose should be \"Choose new hiree\" in %s", __PRETTY_FUNCTION__);
    XCTAssertEqual(newMtg.scheduledHours, .75, @"New meeting scheduledHours should be .75 in %s", __PRETTY_FUNCTION__);
    NSUInteger expectedCount = 2;
    XCTAssertEqual(newMtg.participants.count, expectedCount, @"New meeting should have two participants in %s", __PRETTY_FUNCTION__);
    DBBPerson *lastPerson = [newMtg.participants lastObject];
    XCTAssertEqualObjects(lastPerson.firstName, @"Simon", @"The last participant's first name should be \"Simon\" in %s", __PRETTY_FUNCTION__);
	
    DBBMeeting *mtg2 = [[DBBMeeting alloc] initWithManager:self.manager];
    mtg2.purpose = @"Choose new hiree";
    mtg2.startTimeActual = [NSDate date];
    mtg2.scheduledHours = .75;
    
    p1 = [[DBBPerson alloc] initWithManager:self.manager];
    p1.firstName = @"Joe";
    p1.lastName = @"Schmoe";
    p1.department = @"Support";
    
    p2 = [[DBBPerson alloc] initWithManager:self.manager];
    p2.firstName = @"Sally";
    p2.lastName = @"Smith";
    p2.department = @"Marketing";
    
    success = [p1 saveToDB];
    XCTAssertTrue(success, @"Person 1 should be saved successfully in %s", __PRETTY_FUNCTION__);
    
    success = [p2 saveToDB];
    XCTAssertTrue(success, @"Person 2 should be saved successfully in %s", __PRETTY_FUNCTION__);
    
    mtg2.participants = @[p1, p2];
    success = [mtg2 saveToDB];
    XCTAssertTrue(success, @"Meeting 2 should be saved successfully in %s", __PRETTY_FUNCTION__);
    
    DBBProject *subProject = [[DBBProject alloc] initWithManager:self.manager];
    subProject.name = @"Sub project for testing";
    success = [subProject saveToDB];
    XCTAssertTrue(success, @"Subproject should be saved successfully in %s", __PRETTY_FUNCTION__);
    
    DBBProject *proj = [[DBBProject alloc] initWithManager:self.manager];
    
    proj.name = @"Project for meeting";
    proj.code = @"MTG-4354";
    proj.startDate = [NSDate date];
    proj.endDate = [NSDate date];
    proj.budget = [NSDecimalNumber decimalNumberWithString:@"43.99"];
    proj.meetings = @[mtg1, mtg2, newMtg];
    proj.subProject = subProject;
    success = [proj saveToDB];
    XCTAssertTrue(success, @"Project should be saved successfully in %s", __PRETTY_FUNCTION__);
	
	DBBMeeting *mtg3 = [[DBBMeeting alloc] initWithManager:self.manager];
	mtg3.purpose = @"Fire new hiree";
	mtg3.startTimeActual = [NSDate date];
	mtg3.scheduledHours = .5;
	mtg3.participants = @[p1, p2];
	success = [mtg3 saveToDB];
	XCTAssertTrue(success, @"Meeting 3 should be saved successfully in %s", __PRETTY_FUNCTION__);
	
    success = [DBBMeeting deleteObjects:@[mtg1, mtg2]];
    XCTAssertTrue(success, @"Deleting 2 meetings from project should succeed in %s", __PRETTY_FUNCTION__);
    
    NSArray *allMeetings = [DBBMeeting objectsWithOptions:nil manager:self.manager];
    NSInteger mtgCount = (int)allMeetings.count;
    XCTAssertEqual(mtgCount, 1, @"Meeting array count should equal 1 after deletions in %s", __PRETTY_FUNCTION__);
    
    NSInteger projID = proj.itemID;
    success = [DBBProject deleteObject:proj];
    XCTAssertTrue(success, @"Deleting project should succeed in %s", __PRETTY_FUNCTION__);
    
    options = @{kQueryConditionsKey : [NSString stringWithFormat:@"id = %ld", (long)projID]};
    NSArray *projects = [DBBProject objectsWithOptions:options manager:self.manager];
    NSInteger projCount = (int)projects.count;
    XCTAssertEqual(projCount, 0, @"Project array count should equal 0 after deletion in %s", __PRETTY_FUNCTION__);
}

- (void)testSaveWithQueue
{
	DBBProject *proj = [[DBBProject alloc] initWithManager:self.manager];
	
	// test with missing name for a not-null constraint error
	proj.code = @"MTG-4354";
	proj.startDate = [NSDate date];
	proj.endDate = [NSDate date];
	proj.budget = [NSDecimalNumber decimalNumberWithString:@"43.99"];
	[proj queueSaveToDBWithCompletionBlock:^(BOOL success, NSError *error) {
		XCTAssertTrue(!success, @"Project should NOT be saved successfully in %s", __PRETTY_FUNCTION__);
	}];
	
	// set name
	proj.name = @"Project to test saving with queue";
	[proj queueSaveToDBWithCompletionBlock:^(BOOL success, NSError *error) {
		XCTAssertTrue(success, @"Project should be saved successfully in %s", __PRETTY_FUNCTION__);
	}];
	
	// check for its existence
	NSInteger projID = proj.itemID;
	NSDictionary *options = @{kQueryConditionsKey : [NSString stringWithFormat:@"id = %ld", (long)projID]};
	NSArray *projects = [DBBProject objectsWithOptions:options manager:self.manager];
	NSInteger projCount = (int)projects.count;
	XCTAssertEqual(projCount, 1, @"Project array count should equal 0 after deletion in %s", __PRETTY_FUNCTION__);
}

@end
