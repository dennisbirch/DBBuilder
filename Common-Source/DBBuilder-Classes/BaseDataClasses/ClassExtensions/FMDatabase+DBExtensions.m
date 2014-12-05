//
//  FMDatabase+DBExtensions.m
//
//  Created by Dennis Birch on 9/5/13.
//  Copyright (c) 2013 Dennis Birch. All rights reserved.
//

#import "FMDatabase+DBExtensions.h"
#import "DBManager.h"

@implementation FMDatabase (DBExtensions)

- (NSString *)createStringForTable:(NSString*)tableName manger:(DBManager *)manager
{
    // trim off prefix if necessary
    if ([[tableName substringToIndex:manager.classPrefix.length] isEqualToString:manager.classPrefix]) {
        tableName = [tableName substringFromIndex:manager.classPrefix.length];
    }
    tableName  = [tableName lowercaseString];

    FMResultSet *rs = [self executeQuery:@"select [sql] from sqlite_master where [type] = 'table' and lower(name) = ?", tableName];
    
	
	NSString *returnStr;
	
	if ([rs next]) {
		returnStr = [rs stringForColumn:@"sql"];
	}
    
    //If this is not done FMDatabase instance stays out of pool
    [rs close];
    
    return returnStr;
}

- (NSInteger)db_fieldCountForTable:(NSString *)tableName
{
	FMResultSet *rs = [self getTableSchema:tableName];
	NSInteger count = 0;
	while ([rs next]) {
		count++;
	}
	
	return count;
}

@end
