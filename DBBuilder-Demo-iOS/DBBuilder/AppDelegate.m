//
//  AppDelegate.m
//  DBBuilder
//
//  Created by Dennis Birch on 9/11/13.
//  Copyright (c) 2013 Dennis Birch. All rights reserved.
//

#import "AppDelegate.h"
#import "DBManager.h"
#import	"DBMacros.h"

@interface AppDelegate ()

@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self openDBFile];
	
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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

//- (NSString *)cachesFolderPath
//{
//	NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
//	
//	return url.path;
//}

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

@end
