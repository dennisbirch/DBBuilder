//
//  NSDateFormatter+DBExtensions.m
//  WareBase
//
//  Created by Dennis Birch on 5/27/15.
//  Copyright (c) 2015 Dennis Birch. All rights reserved.
//

#import "NSDateFormatter+DBExtensions.h"

@implementation NSDateFormatter (DBExtensions)

+ (NSDateFormatter *)db_sqlDateFormatterWithoutTime
{
    static NSDateFormatter *df = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        
        df = [[NSDateFormatter alloc] init];
        [df setLocale:enUSPOSIXLocale];
        [df setDateFormat:@"yyyy'-'MM'-'dd'"];
        [df setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    });
    
    return df;
}

+ (NSDateFormatter *)db_sqlDateFormatter
{
    static NSDateFormatter *df = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        
        df = [[NSDateFormatter alloc] init];
        [df setLocale:enUSPOSIXLocale];
        [df setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm':'ss"];
        [df setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    });
    
    return df;
}

+ (NSDateFormatter *)db_shortDateOnlyFormatter
{
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterShortStyle;
        formatter.timeStyle = NSDateFormatterNoStyle;
    });
    
    return formatter;
}

@end
