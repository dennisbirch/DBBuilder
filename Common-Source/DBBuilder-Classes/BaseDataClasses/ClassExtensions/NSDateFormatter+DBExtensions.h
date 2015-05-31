//
//  NSDateFormatter+DBExtensions.h
//  WareBase
//
//  Created by Dennis Birch on 5/27/15.
//  Copyright (c) 2015 Dennis Birch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDateFormatter (DBExtensions)

// returns a date formatter for SQL timestamp conversions
+ (NSDateFormatter *)db_sqlDateFormatter;
// returns a date formatter for SQL date-only conversions
+ (NSDateFormatter *)db_sqlDateFormatterWithoutTime;
// returns a date formatter for short date-only conversions
+ (NSDateFormatter *)db_shortDateOnlyFormatter;

@end
