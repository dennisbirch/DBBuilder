//
//  ObjCClassUtil.m
//
//  Created by Dennis Birch on 9/5/13.
//  Copyright (c) 2013 Dennis Birch. All rights reserved.
//

#import "ObjCClassUtil.h"
#import "objc/runtime.h"
#import "objc/objc.h"
#import "DBTableRepresentation.h"

@implementation ObjCClassUtil

+ (NSDictionary *)atomicTypesDict
{
	static NSDictionary *typesDict = nil;
	
	if (typesDict == nil) {
		typesDict = @{
				@"c" : @"BOOL",
	@"i" : @"NSInteger",
	@"s" : @"short",
	@"l" : @"long",
	@"q" : @"long long",
	@"C" : @"unsigned char",
	@"I" : @"NSUInteger",
	@"S" : @"unsigned short",
	@"L" : @"unsigned long",
	@"Q" : @"unsigned long long",
	@"f" : @"float",
	@"d" : @"double",
	@"B" : @"bool",
	@"*" : @"char *"
	};
	}
	
	return typesDict;
}

+ (NSString *)typeForProperty:(objc_property_t)property
{
    const char *attributes = property_getAttributes(property);
	NSString *propStr = [[NSString alloc] initWithCString:attributes encoding:NSUTF8StringEncoding];
	
	// get the string up to the first comma
	NSUInteger commaLoc = [propStr rangeOfString:@","].location;
	NSString *attribute = [propStr substringToIndex:commaLoc];
	
	while (attribute != nil) {
		NSString *atr0 = [attribute substringWithRange:NSMakeRange(0, 1)];
		NSString *atr1 = [attribute substringWithRange:NSMakeRange(1, 1)];
		
		if ([atr0 isEqualToString:@"T"] && ![atr1 isEqualToString:@"@"]) {
			NSString *atomicType = [attribute substringWithRange:NSMakeRange(1, attribute.length - 1)];
			if ([[[ObjCClassUtil atomicTypesDict] allKeys] containsObject:atomicType]) {
				return [ObjCClassUtil atomicTypesDict][atomicType];
			} else {
				return atomicType;
			}
		} else if ([atr0 isEqualToString:@"T"] && [atr1 length] == 2) {
            // it's an ObjC id type:
            return @"id";
        } else if ([atr0 isEqualToString:@"T"] && [atr1 isEqualToString:@"@"]) {
            // it's another ObjC object type:
			// trim off the first two characters and return the remainder
			NSString *result = [attribute substringWithRange:NSMakeRange(3, attribute.length - 4)];
            return result;
        }
	}
	return @"";
}


+ (NSDictionary *)classPropsFor:(Class)cls
{
    if (cls == NULL) {
        return nil;
    }
	
    NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(cls, &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if (propName
			&& strcmp(propName, "itemID")!= 0)
		{
            NSString *propertyName = [NSString stringWithUTF8String:propName];
			NSString *propertyType = [self typeForProperty:property];

            results[propertyName] = propertyType;
        }
    }
    free(properties);
	
	
	// Now see if we need to map any superclasses as well.
    Class superClass = class_getSuperclass( cls );
    if ( superClass != nil && ! [superClass isEqual:[NSObject class]] )
    {
        NSDictionary *superDict = [self classPropsFor:[superClass class]];
        [results addEntriesFromDictionary:superDict];
    }
	
   return [results copy];
}

+ (NSArray *)tableNamesFromClassesForManager:(DBManager *)manager
{
	int numClasses;

	Class * classes = NULL;
	unsigned int size = sizeof(Class);
	
	numClasses = objc_getClassList(NULL, 0);
	
	if (numClasses > 0 )
	{
		classes = (Class *) realloc(classes, size * (unsigned)numClasses);
		numClasses = objc_getClassList(classes, numClasses);
	}
	
	NSMutableArray *names = [NSMutableArray array];
	NSString *prefix = [manager.classPrefix copy];
	for (int i = 0; i < numClasses; i++) {
		if (class_respondsToSelector(classes[i], @selector(isDBTableRepresentationClass))) {
			NSString *name = [NSString stringWithUTF8String:object_getClassName(classes[i])];
			name = [name stringByReplacingOccurrencesOfString:prefix withString:@""];
			if (![name isEqualToString:@"DBTableRepresentation"] &&
				![name isEqualToString:@"ableRepresentation"]) { // for case of "DBT" prefix
				[names addObject:name];
			}
		}
	}
	
	free(classes);
	
	return [names copy];
}


@end
