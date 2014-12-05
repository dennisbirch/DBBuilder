//
//  NSString+DBExtensions.m
//
//  Created by Dennis Birch on 9/5/13.
//  Copyright (c) 2013 Dennis Birch. All rights reserved.
//

#import "NSString+DBExtensions.h"

@implementation NSString (DBExtensions)

- (NSDate *)db_dateForSQLDateString
{
	NSDateFormatter *df = [NSString db_sqlDateFormatter];
	NSDate *date = nil;
	
	@try {
		date = [df dateFromString:self];
	}
	@catch (NSException *exception) {
		return nil;
	}
	
	return date;
}

- (NSString *)db_sqlify
{
	NSString *outStr = [self stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
	return [NSString stringWithFormat:@"'%@'", outStr];
}


+ (NSDateFormatter *)db_sqlDateFormatter
{
	static NSDateFormatter *df = nil;
	
	if (df == nil) {
		NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
		
		df = [[NSDateFormatter alloc] init];
		[df setLocale:enUSPOSIXLocale];
		[df setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm':'ss"];
		[df setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	}
	
	return df;
}


- (NSString *)db_leftEscapedString
{
    NSString *left = [[self substringToIndex:[self rangeOfString:@"="].location - 1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *right = [self stringByReplacingOccurrencesOfString:left withString:@""];
    
    return [NSString stringWithFormat:@"%@ %@",[left db_sqlify], right];
}


- (NSString *)db_rightEscapedString
{
	NSUInteger location = [self rangeOfString:@"="].location;
	if (location == NSNotFound) {
		// check for "LIKE"
		location = [[self lowercaseString] rangeOfString:@"like"].location;
		if (location == NSNotFound) {
			return self;
		}
		
		location +=4;
	}
	
    NSString *left = [self substringToIndex:location + 1];
    NSString *right = [[[self stringByReplacingOccurrencesOfString:left withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] db_sqlify];
    
    
    return [left stringByAppendingString:right];
}

+ (NSString *)db_EndsWithSearchTerm:(NSString *)searchTerm forColumn:(NSString *)column
{
	return [column db_EndsWithClauseForSearchTerm:searchTerm];
}

+ (NSString *)db_StartsWithSearchTerm:(NSString *)searchTerm forColumn:(NSString *)column
{
	return [column db_StartsWithClauseForSearchTerm:searchTerm];
}

+ (NSString *)db_ContainsSearchTerm:(NSString *)searchTerm forColumn:(NSString *)column
{
	return [column db_ContainsClauseForSearchTerm:searchTerm];
}

- (NSString *)db_StartsWithClauseForSearchTerm:(NSString *)searchTerm
{
	return [self stringByAppendingString:[NSString stringWithFormat:@" LIKE %@%%", searchTerm]];
}

- (NSString *)db_EndsWithClauseForSearchTerm:(NSString *)searchTerm
{
	return [self stringByAppendingString:[NSString stringWithFormat:@" LIKE %%%@", searchTerm]];
}

- (NSString *)db_ContainsClauseForSearchTerm:(NSString *)searchTerm
{
	return [self stringByAppendingString:[NSString stringWithFormat:@" LIKE %%%@%%", searchTerm]];
}

@end
