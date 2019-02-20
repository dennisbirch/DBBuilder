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

- (NSString *)filePath {
    NSURL *documentsFolderURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSString *path = [documentsFolderURL.path stringByAppendingPathComponent:@"DBBuilder Test.sqlite"];
    return path;
}

- (void)performSetUp
{
    NSString *path = self.filePath;

    self.manager = [DBManager managerWithFilePath:path];
	
	[self.manager configureWithFilePath:path classPrefix:@"DBB" idColumnName:@"id"];
	
	
	// start off with a clean slate
	NSArray *participants = [DBBPerson allPeople];
	
	// test multi-delete
    // TODO: Move to test case
	BOOL success = [DBBPerson deleteObjects:participants];
	XCTAssertTrue(success, @"Deleting all people should return True in %s", __PRETTY_FUNCTION__);
	
	NSUInteger count = [self.manager countForTable:@"person"];
	XCTAssertEqual(count, (unsigned)0, @"The count of people should be 0 in %s", __PRETTY_FUNCTION__);
	
	// test deleting individual objects
	NSArray *projects = [DBBProject objectsWithOptions:nil manager:self.manager];
	for (DBBProject *project in projects) {
		success = [DBBProject deleteObject:project];
		XCTAssertTrue(success, @"Deleting a single project should return True in %s", __PRETTY_FUNCTION__);
	}
	count = [self.manager countForTable:@"project"];
	XCTAssertEqual(count, (unsigned)0, @"The count of projects should be 0 in %s", __PRETTY_FUNCTION__);
}

- (void)performTeardown {
    NSString *path = [self filePath];
    NSError *error = nil;
    [NSFileManager.defaultManager removeItemAtPath:path error:&error];
    if (error != nil) {
        NSLog(@"Error deleting file: %@", error.localizedDescription);
    }
}

- (NSArray <DBBPerson *>*)twoPeople {
    DBBPerson *p1 = [[DBBPerson alloc] initWithManager:self.manager];
    p1.firstName = @"Dennis";
    p1.lastName = @"Birch";
    p1.department = @"Engineering";
    
    DBBPerson *p2 = [[DBBPerson alloc] initWithManager:self.manager];
    p2.firstName = @"Simon";
    p2.lastName = @"Sez";
    p2.department = @"Management";

    return @[p1, p2];
}

@end
