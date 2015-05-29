//
//  NSDate+DBExtensions.h
//  DBBuilder
//
//  Created by Dennis Birch on 9/21/13.
//  Copyright (c) 2013 Dennis Birch. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <Foundation/Foundation.h>

@interface NSDate (DBExtensions)

// returns a string with the receiving date's value expressed in SQL datestamp format
- (NSString *)db_sqlDateString;
// returns a string with the receiving date's value expressed in "short" date format (without the time)
- (NSString *)db_displayDate;
// returns a string with the receiving date's value expressed in "short" date and time format
- (NSString *)db_displayDateTime;
// returns a date with the receiving date's hours, minutes and seconds set to 0, representing its time at midnight
- (NSDate *)db_midnightDate;

// returns a string that can be used for queries with "date = xxx" conditions
- (NSString *)db_queryStringForDateMatchOnColumn:(NSString *)columnName;

@end
