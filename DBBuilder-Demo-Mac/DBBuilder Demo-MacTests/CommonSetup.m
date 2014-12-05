//
//  CommonSetup.m
//  DBBuilder-Demo-Mac
//
//  Created by Dennis Birch on 12/3/14.
//  Copyright (c) 2014 Dennis Birch. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CommonSetup.h"
#import "DBManager.h"
#import <Cocoa/Cocoa.h>
#import "FMDatabase.h"
#import "DBBProject.h"
#import "DBBMeeting.h"
#import "DBBPerson.h"
#import "AppDelegate.h"

@implementation CommonSetup

- (void)performSetUp
{
	
	NSURL *documentsFolderURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
	NSString *path = [documentsFolderURL.path stringByAppendingPathComponent:@"DBBuilder Test.sqlite"];

	self.manager = [DBManager managerWithFilePath:path];
	
	[self.manager configureWithFilePath:path classPrefix:@"DBB" idColumnName:@"id"];
	
	
	// start off with a clean slate
	NSArray *participants = [DBBPerson allPeople];
	
	// test multi-delete
	BOOL success = [DBBPerson deleteObjects:participants];
	XCTAssertTrue(success, @"Deleting all people should return True in %s", __PRETTY_FUNCTION__);
	
	NSUInteger count = [self.manager countForTable:@"person"];
	XCTAssertEqual(count, (unsigned)0, @"The count of people should be 0 in %s", __PRETTY_FUNCTION__);
	
	// test deleting with direct execute statement to FMDatabase
	NSString *sql = @"DELETE FROM meeting";
	success = [self.manager.database executeStatements:sql];
	XCTAssertTrue(success, @"Deleting with an execute statement to FMDatabase should return success in %s", __PRETTY_FUNCTION__);
	count = [self.manager countForTable:@"meeting"];
	XCTAssertEqual(count, (unsigned)0, @"The count of meetings should be 0 in %s", __PRETTY_FUNCTION__);
	
	// test deleting individual objects
	NSArray *projects = [DBBProject objectsWithOptions:nil manager:self.manager];
	for (DBBProject *project in projects) {
		success = [DBBProject deleteObject:project];
		XCTAssertTrue(success, @"Deleting a single project should return True in %s", __PRETTY_FUNCTION__);
	}
	count = [self.manager countForTable:@"project"];
	XCTAssertEqual(count, (unsigned)0, @"The count of projects should be 0 in %s", __PRETTY_FUNCTION__);
}


@end
