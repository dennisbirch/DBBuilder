//
//  NSString+DBExtensions.h
//
//  Created by Dennis Birch on 9/5/13.
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

@interface NSString (DBExtensions)

// returns a date that corresponds to a SQL-formatted timestamp string
- (NSDate *)db_dateForSQLDateString;
// returns a date that corresponds to a short-date formatted string
- (NSDate *)db_dateForShortDateString;

// returns a SQL-formatted timestamp for a date string in "short" format
- (NSString *)db_sqlDateStringForShortDate;
// returns a SQL-formatted date (no time component) for a date string in "short" format
- (NSString *)db_sqlDateStringForShortDateWithoutTime;

// returns a SQL-escaped string for the receiver
- (NSString *)db_sqlify;

// returns a string with everything to the left of a "=" sign SQL-escaped
- (NSString *)db_leftEscapedString;
// returns a string with everything to the right of a "=" sign SQL-escaped
- (NSString *)db_rightEscapedString;

// SQL SUBSTRING SEARCH HELPERS
// You can use these helpers to create Condition clauses for string matching queries
// e.g. [NSString db_EndsWithSearchTerm:@"book" forColumn:@"merchandise" returns:
// "merchandise LIKE %hello", which if included in a condition clause, would match on any
// entries in the merchandise column that end in "hello"
+ (NSString *)db_EndsWithSearchTerm:(NSString *)searchTerm forColumn:(NSString *)column;
// returns a condition clause that matches entries in column that start with searchTerm
+ (NSString *)db_StartsWithSearchTerm:(NSString *)searchTerm forColumn:(NSString *)column;
// returns a condition clause that matches entries in column that contain searchTerm
+ (NSString *)db_ContainsSearchTerm:(NSString *)searchTerm forColumn:(NSString *)column;

@end
