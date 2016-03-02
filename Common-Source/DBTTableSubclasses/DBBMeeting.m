//
//  DBBMeeting.m
//  DBBuilder
//
//  Created by Dennis Birch on 9/22/13.
//  Copyright (c) 2013 Dennis Birch. All rights reserved.
//

#import "DBBMeeting.h"
#import "DBBPerson.h"

@implementation DBBMeeting

+ (NSDictionary *)tableAttributes
{
    return @{@"participants" : @[[kJoinTableMappingAttributeKey stringByAppendingString:@":DBBPerson"],
								 kCascadingArrayDeletionAttributeKey]
			 };
}

- (NSString *)description
{
    return  [NSString  stringWithFormat:@"Project: %@, Purpose: %@, Scheduled: %02f, Start Time: %@, Finish Time: %@, Partipants: %@",
             self.project, self.purpose, self.scheduledHours, self.startTimeActual, self.finishTimeActual, self.participants];
}

- (BOOL)isEqual:(DBBMeeting *)otherMeeting
{
	if (![otherMeeting isKindOfClass:[self class]]) {
		return NO;
	}

	return [super isEqual:otherMeeting] && [self.purpose isEqualToString:otherMeeting.purpose];
}


+ (NSArray *)allMeetings
{
	NSDictionary *queryOptions = @{kQuerySortingKey : @"startTimeActual"};
	NSArray *result = [DBBMeeting objectsWithOptions:queryOptions manager:[DBManager defaultDBManager]];
	
	return result;
}


- (void)removeParticipant:(DBBPerson *)person
{
	if (person == nil) {
		return;
	}
	NSMutableArray *participants = [self.participants mutableCopy];
	[participants removeObject:person];
	self.participants = [participants copy];
}

- (void)addParticipant:(DBBPerson *)person
{
	if (person == nil) {
		return;
	}
	
	NSMutableArray *participants = (self.participants == nil) ? [NSMutableArray new] : [self.participants mutableCopy];
	if ([participants indexOfObject:person] == NSNotFound) {
		[participants addObject:person];
	}
	self.participants = [participants copy];
}

@end
