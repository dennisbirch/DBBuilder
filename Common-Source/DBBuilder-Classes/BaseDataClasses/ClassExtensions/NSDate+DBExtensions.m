//
//  NSDate+DBExtensions.m
//  DBBuilder
//
//  Created by Dennis Birch on 9/21/13.
//  Copyright (c) 2013 Dennis Birch. All rights reserved.
//

#import "NSDate+DBExtensions.h"
#import "NSString+DBExtensions.h"
#import "NSDateFormatter+DBExtensions.h"

@implementation NSDate (DBExtensions)

- (NSString *)db_sqlDateString
{
    NSDateFormatter *formatter = [NSDateFormatter db_sqlDateFormatter];
    NSString *result = [formatter stringFromDate:self];
    return result;
}

- (NSString *)db_sqlDateStringWithoutTime
{
    NSDateFormatter *formatter = [NSDateFormatter db_sqlDateFormatterWithoutTime];
    NSString *result = [formatter stringFromDate:self];
    return result;
}

- (NSString *)db_displayDate
{
    NSDateFormatter *formatter = [NSDateFormatter db_shortDateOnlyFormatter];
    return [formatter stringFromDate:self];
}

- (NSString *)db_displayDateTime
{
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterShortStyle;
        formatter.timeStyle = NSDateFormatterShortStyle;
    });
    
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

- (NSString *)db_queryStringForDateMatchOnColumn:(NSString *)columnName
{
    NSDate *nextDate = [self nextDate];
    NSString *result = [NSString stringWithFormat:@"%@ < '%@' AND %@ > '%@'", columnName, [nextDate db_sqlDateStringWithoutTime], columnName, [self db_sqlDateStringWithoutTime]];
    return result;
}

- (NSDate *)nextDate
{
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.day = 1;
    components.second = -1;
    NSDate *newDate = [gregorianCalendar dateByAddingComponents:components toDate:self options:0];
    return newDate;
}

@end
