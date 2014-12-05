//
//  NSDictionary+SafeAccessors.m
//
//  Created by Dennis Birch on 8/24/12.
//  Copyright (c) 2012 Dennis Birch. All rights reserved.
//

#import "NSDictionary+SafeAccessors.h"

@implementation NSDictionary (SafeAccessors)

- (double)db_doubleValueForKey:(id)key
{
	key = [self db_caseSensitiveKey:key];
	if ([key isEqualToString:@""]) {
		return 0;
	}
	
	id obj = [self objectForKey:key];
	if (obj == [NSNull null]) {
		return 0;
	}
	
	return [obj doubleValue];
}


- (BOOL)db_boolValueForKey:(id)key
{
	key = [self db_caseSensitiveKey:key];
	if ([key isEqualToString:@""]) {
		return NO;
	}
	
	id obj = [self objectForKey:key];
	if (obj == [NSNull null]) {
		return NO;
	}
	
	return [obj boolValue];
}


- (NSInteger)db_intValueForKey:(id)key
{
	key = [self db_caseSensitiveKey:key];
	if ([key isEqualToString:@""]) {
		return 0;
	}
	
	id obj = [self objectForKey:key];
	if (obj == [NSNull null]) {
		return 0;
	}
	
	NSInteger value = [obj integerValue];
	return value;
}

- (NSString *)db_stringForKey:(NSString *)key
{
	key = [self db_caseSensitiveKey:key];
	if ([key isEqualToString:@""]) {
		return @"";
	}
	
	id obj = [self objectForKey:key];
	if (obj == [NSNull null]) {
		return @"";
	}
	
	return self[key];
}

- (BOOL)db_hasKey:(NSString *)key
{	
	key = [self db_caseSensitiveKey:key];
	return ![key isEqualToString:@""];
}

- (NSString *)db_caseSensitiveKey:(NSString *)key
{
	NSEnumerator *enumerator = self.keyEnumerator;
	NSString *enumKey;
	do {
		 enumKey = [enumerator nextObject];
		if ([[key uppercaseString] isEqualToString:[enumKey uppercaseString]]) {
			return enumKey;
		}
	} while (enumKey != nil);
	
	
	
	return @"";
}

@end
