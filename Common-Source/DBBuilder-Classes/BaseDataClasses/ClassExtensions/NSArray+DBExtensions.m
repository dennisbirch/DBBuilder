//
//  NSArray+DBExtensions.m
//
//  Created by Dennis Birch on 9/7/13.
//  Copyright (c) 2013 Dennis Birch. All rights reserved.
//

#import "NSArray+DBExtensions.h"
#import "NSString+DBExtensions.h"

@implementation NSArray (DBExtensions)

- (NSUInteger)db_indexForCaseInsensitiveMatchOnString:(NSString *)aString
{
	if (aString == nil) {
		return NSNotFound;
	}
	
	NSUInteger found = [self indexOfObjectPassingTest:^BOOL(NSString *inString, NSUInteger idx, BOOL *stop) {
		if ([inString isKindOfClass:[NSString class]] && [inString caseInsensitiveCompare:aString] == NSOrderedSame) {
			*stop = YES;
		}
		return *stop;
	}];
	
	return found;
}

- (NSArray *)db_sqlEscapedArray
{
    NSMutableArray *newArray = [NSMutableArray arrayWithCapacity:self.count];
    for (unsigned int i = 0; i < self.count; i++) {
        if ([self[i] isKindOfClass:[NSString class]]) {
            [newArray addObject:[(NSString *)(self[i]) db_sqlify]];
        } else {
            [newArray addObject:self[i]];
        }
    }
    
    return [newArray copy];
}


- (NSArray *)db_leftSQLEscapedArray
{
    NSMutableArray *newArray = [NSMutableArray arrayWithCapacity:self.count];
    for (unsigned int i = 0; i < self.count; i++) {
        id item = self[i];
        if ([item isKindOfClass:[NSString class]]) {
            [newArray addObject:[(NSString *)item db_leftEscapedString]];
        } else {
            [newArray addObject:self[i]];
        }
    }
    
    return [newArray copy];
}



- (NSArray *)db_rightSQLEscapedArray
{
    NSMutableArray *newArray = [NSMutableArray arrayWithCapacity:self.count];
    for (unsigned int i = 0; i < self.count; i++) {
        id item = self[i];
        if ([item isKindOfClass:[NSString class]]) {
            [newArray addObject:[(NSString *)item db_rightEscapedString]];
        } else {
            [newArray addObject:self[i]];
        }
    }
    
    return [newArray copy];
}

- (BOOL)db_arrayContainsArrays
{
    for (id subObject in self)
    {
        if ([subObject isKindOfClass:[NSArray class]]) {
            return YES;
        }
    }
    
    return NO;
}

@end
