//
//  AppDelegate.m
//  DBBuilder Demo-Mac
//
//  Created by Dennis Birch on 11/21/14.
//  Copyright (c) 2014 Dennis Birch. All rights reserved.
//

#import "AppDelegate.h"
#import "DBBProjectListWindowController.h"
#import "DBManager.h"
#import "DBMacros.h"

@interface AppDelegate ()

@property (nonatomic, strong) DBBProjectListWindowController *mainWinController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application

	[self openDBFile];
	
	self.mainWinController = [[DBBProjectListWindowController alloc] initWithWindowNibName:@"DBBProjectListWindowController"];
	[self.mainWinController showWindow:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}


- (NSString *)databasePath
{
	NSString *path = [self documentsFolderPath];
	
	path = [path stringByAppendingPathComponent:@"DB Builder.sqlite"];
	
	return path;
}

- (NSString *)documentsFolderPath
{
	NSURL *documentsFolderURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
	
	return documentsFolderURL.path;
}


- (BOOL)openDBFile
{
	DBManager *dbManager = [DBManager defaultDBManager];
	[dbManager configureWithFilePath:[self databasePath] classPrefix:@"DBB" idColumnName:@"id"];
	
	DBDBLog(@"Path for database file: %@", [self databasePath]);
	
	FMDatabase *db = [dbManager database];
	
	if (![db open]) {
		NSLog(@"Error opening file: %@", db.lastErrorMessage);
		return NO;
	}
	
	return YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}


@end
