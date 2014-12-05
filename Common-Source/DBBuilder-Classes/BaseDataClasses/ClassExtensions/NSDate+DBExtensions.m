//
//  NSDate+DBExtensions.m
//  DBBuilder
//
//  Created by Dennis Birch on 9/21/13.
//  Copyright (c) 2013 Dennis Birch. All rights reserved.
//

#import "NSDate+DBExtensions.h"
#import "NSString+DBExtensions.h"

@implementation NSDate (DBExtensions)

- (NSString *)db_sqlDateString
{
	NSDateFormatter *formatter = [NSString db_sqlDateFormatter];
	NSString *result = [formatter stringFromDate:self];
	return result;
}

- (NSString *)db_displayDate
{
	static NSDateFormatter *formatter;
	if (formatter == nil) {
		formatter = [[NSDateFormatter alloc] init];
		formatter.dateStyle = NSDateFormatterShortStyle;
		formatter.timeStyle = NSDateFormatterNoStyle;
	}
	
	return [formatter stringFromDate:self];
}

- (NSString *)db_displayDateTime
{
	static NSDateFormatter *formatter;
	if (formatter == nil) {
		formatter = [[NSDateFormatter alloc] init];
		formatter.dateStyle = NSDateFormatterShortStyle;
		formatter.timeStyle = NSDateFormatterShortStyle;
	}
	
	return [formatter stringFromDate:self];
}


- (NSDate *)db_midnightDate
{
	NSCalendar *cal = [NSCalendar currentCalendar];
	NSDateComponents *components = [cal components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay |NSCalendarUnitHour | NSCalendarUnitMinute fromDate:self];
	components.hour = 0;
	components.minute = 0;
	
	return [cal dateFromComponents:components];
}


@end
