//
//  DBBPerson.m
//  DBBuilder
//
//  Created by Dennis Birch on 10/2/13.
//  Copyright (c) 2013 Dennis Birch. All rights reserved.
//

#import "DBBPerson.h"
//#import "DBManager.h"

@implementation DBBPerson

+ (NSDictionary *)tableAttributes
{
    return @{@"firstName" : kNotNullAttributeKey,
             @"lastName" : kNotNullAttributeKey
             };
}

+ (NSArray *)allPeople
{
    NSArray *all = [DBBPerson objectsWithOptions:nil manager:[DBManager defaultDBManager]];
    
    return all;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"First: %@, MI: %@, Last: %@, Dept: %@, @Image: %@", self.firstName, self.middleInitial, self.lastName, self.department, [self.imageData subdataWithRange:NSMakeRange(0, 100)]];
}


- (NSString *)fullName
{
    NSString *name = self.firstName;
    if (name.length > 0) {
        name = [name stringByAppendingString:@" "];
    }
    
    return [name stringByAppendingString:self.lastName];
}

- (NSString *)fullNameAndDepartment
{
    NSString *fullName = [self fullName];
    if (fullName.length > 0) {
        fullName = [fullName stringByAppendingString:@" "];
    }
    
    if (self.department.length > 0) {
        fullName = [fullName stringByAppendingFormat:@" — %@", self.department];
    }
    
    return fullName;
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    typeof(self) otherPerson = object;
    
    return [self.firstName isEqualToString:otherPerson.firstName] &&
        [self.middleInitial isEqualToString:otherPerson.middleInitial] &&
        [self.lastName isEqualToString:otherPerson.lastName] &&
        [self.department isEqualToString:otherPerson.department];
}

#if TARGET_OS_IPHONE
- (UIImage *)image
{
	UIImage *image = [UIImage imageWithData:self.imageData];
	return image;
}


- (void)setJPEGImage:(UIImage *)image withCompression:(CGFloat)compression
{
	// compression range from 0.0 to 1.0
	self.imageData = UIImageJPEGRepresentation(image, compression);
}

- (void)setPNGImage:(UIImage *)image
{
	self.imageData = UIImagePNGRepresentation(image);
}
#endif

@end
