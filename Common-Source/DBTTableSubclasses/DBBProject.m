//
//  DBBProject.m
//  DBBuilder
//
//  Created by Dennis Birch on 9/11/13.
//  Copyright (c) 2013 Dennis Birch. All rights reserved.
//

#import "DBBProject.h"
#import "DBBMeeting.h"

@implementation DBBProject


- (NSString *)description
{
    return [NSString stringWithFormat:@"ID: %ld, Name: %@, Code: %@, Start: %@, End: %@, Budget: %@, Subproject: %@",
            (long)self.itemID, self.name, self.code, self.startDate, self.endDate, self.budget, self.subProject];
}

+ (NSDictionary *)tableAttributes
{
	return @{@"name" : kNotNullAttributeKey,
			 @"meetings" : [kJoinTableMappingAttributeKey stringByAppendingString:@":DBBMeeting"],
			 @"tags" : [kJoinTableMappingAttributeKey stringByAppendingString:@":NSArray"],
			 };
}

// this is a totally arbitrary usage of the overriddenColumnNames method, meant only to
// exercise this capability for demo purposes
+ (NSDictionary *)overriddenColumnNames
{
	return @{@"subProject" : @"dependentproject"};
}


- (void)addMeeting:(DBBMeeting *)meeting
{
	if (meeting == nil) {
		return;
	}
	
	if (self.meetings == nil) {
		self.meetings = [NSArray new];
	}
	
	if ([self.meetings indexOfObject:meeting] == NSNotFound) {
		NSMutableArray *temp = [self.meetings mutableCopy];
		[temp addObject:meeting];
		self.meetings = [temp copy];
	}
}

- (void)removeMeeting:(DBBMeeting *)meeting
{
	NSMutableArray *temp = (self.meetings == nil) ? [NSMutableArray new] : [self.meetings mutableCopy];
	[temp removeObject:meeting];
	self.meetings = [temp copy];
}

@end
