
//  DBTableRepresentation.m
//
//  Created by Dennis Birch on 6/8/12.
//  Copyright (c) 2012 Dennis Birch. All rights reserved.
//

#import "DBTableRepresentation.h"
#import "ObjCClassUtil.h"
#import "NSDictionary+SafeAccessors.h"
#import "NSString+DBExtensions.h"
#import "NSArray+DBExtensions.h"
#import "NSDate+DBExtensions.h"
#import "FMDatabaseQueue.h"
#import	"DBMacros.h"

@interface DBTableRepresentation ()

@property (nonatomic, assign, readwrite) NSInteger itemID;

@end

@implementation DBTableRepresentation

NSString *kInsertForJoinTable = @"INSERT_FOR_JOIN_TABLE";
NSString *kItemIDForInserts = @"ITEM_ID_FOR_INSERTS";
NSString *kIDSuffix = @"_id";

#pragma mark - Initializers

- (instancetype)init
{
	if (self = [super init]) {
		if ([self class] == [DBTableRepresentation class]) {
			return nil;
		}
		if (_manager == nil) {
			_manager = [DBManager defaultDBManager];
		}
		
		[self cacheDBProperties];
	}
	
	return self;
}

- (instancetype)initWithID:(NSInteger)itemID manager:(DBManager *)manager
{
	if (self = [self init]) {
		_manager = manager;
		
		[self cacheDBProperties];

        if ([self tableName] == nil || [[self tableName] isEqualToString:@""]) {
			return nil;
		}

		NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", [self tableName], manager.idColumnName];
		FMResultSet *rs = [_manager.database executeQuery:query, @(itemID)];

		if ([_manager.database lastErrorCode] != 0) {
			return nil;
		}
		
		if ([rs next]) {
			[self loadPropertyValuesForResultSet:rs];
			return self;
		}
	}
	
	// something went wrong, so...
	return nil;
}


- (instancetype)initWithManager:(DBManager *)manager
{
	if (self = [super init]) {
		if (manager == nil) {
			manager = [DBManager defaultDBManager];
		}
		
		_manager = manager;
	}
	
	[self cacheDBProperties];

    if ([self tableName] == nil || [[self tableName] isEqualToString:@""]) {
        return nil;
    }
    
	return  self;
}


- (instancetype)initWithDictionary:(NSDictionary *)dict manager:(DBManager *)manager
{
	if (self = [super init]) {
		_manager = manager;
		[self cacheDBProperties];
		
        if ([self tableName] == nil || [[self tableName] isEqualToString:@""]) {
            return nil;
        }
        
		NSString *key = manager.idColumnName;
		if ([[dict allKeys]containsObject:key]) {
			_itemID = [dict[key] integerValue];
		}
				
		NSString *dateStr = nil;
		key = @"creationDate";
		if ([dict db_hasKey:key] && dict[key] != [NSNull null]) {
			dateStr = dict[key];
			_creationDate = [dateStr db_dateForSQLDateString];
		}
		
		key = @"modificationDate";
		if ([dict db_hasKey:key] && dict[key] != [NSNull null]) {
			dateStr = dict[key];
			_modificationDate = [dateStr db_dateForSQLDateString];
		}

		// populate instance with values
		[self setValuesForItem:self fromResultDictionary:dict];
}
	
	return self;
}

+ (instancetype)savedInstanceWithValues:(NSDictionary *)values manager:(DBManager *)manager
{
	DBTableRepresentation *instance = [[self alloc]initWithDictionary:values manager:manager];
	
	BOOL success = [instance saveToDB];
	if (success) {
		return instance;
	}

	// failed...
	return nil;
}

#pragma mark - Accessing Data Objects

+ (NSArray *)objectsWithOptions:(NSDictionary *) options manager:(DBManager *)manager
{
    NSString *sql = [self sqlStringWithOptions:options manager:manager];
	
	FMResultSet *result = [manager.database executeQuery:sql];
	
	NSError *dbError = manager.database.lastError;
	if (manager.database.lastErrorCode  != 0) {
        NSLog(@"Error accessing records in %s: %@\nQuery: %@", __PRETTY_FUNCTION__, [dbError localizedDescription], sql);
    }
    
    DBTableRepresentation *instance = [[[self class] alloc] initWithManager:manager];
    return [instance arrayOfObjectsForResultSet:result];
}

+ (void)queueObjectsWithOptions:(NSDictionary *)options manager:(DBManager *)manager completionBlock:(void(^)(NSArray *resultsArray, NSError *error))completion
{
    NSString *sql = [self sqlStringWithOptions:options manager:manager];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:manager.filePath];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql];
        NSError *dbError = manager.database.lastError;
        if (manager.database.lastErrorCode  != 0) {
            completion(nil, dbError);
            NSLog(@"Error accessing records in %s: %@\nQuery: %@", __PRETTY_FUNCTION__, [dbError localizedDescription], sql);

        } else {
            DBTableRepresentation *instance = [[self alloc] initWithManager:manager];
            NSArray *results = [instance arrayOfObjectsForResultSet:rs];
			[db closeOpenResultSets];
            completion([NSArray arrayWithArray:results], nil);
        }
    }];
}

+ (NSArray *)allIDsForTableWithManager:(DBManager *)manager
{
	DBTableRepresentation *instance = [[self alloc] initWithManager:manager];
	NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM %@", manager.idColumnName, instance.tableName];
	FMResultSet *results = [manager.database executeQuery:sql];
	if (manager.database.lastErrorCode > 0) {
		NSLog(@"Error executing SQL for IDs array: %@", manager.database.lastErrorMessage);
		return nil;
	}
	
	NSMutableArray *idsArray = [NSMutableArray new];
	while ([results next]) {
		NSDictionary *resultsDict = results.resultDictionary;
		[idsArray addObject:resultsDict[manager.idColumnName]];
	}
	
	return idsArray;
}

#pragma mark - Deleting objects

+ (BOOL)deleteObject:(DBTableRepresentation *)obj
{
	if (obj == nil) {
		return YES;
	}

	NSInteger itemID = obj.itemID;
    DBManager *manager = obj->_manager;
    NSString *sql;
    NSString *tableName = [obj tableName];
	
    // see if we need to remove any children
    sql = [self childDeleteSQLForItem:obj manager:manager];
    if (sql.length > 0 && ![manager.database executeUpdate:sql]) {
        NSLog(@"Error deleting sub-object references: %@", manager.database.lastErrorMessage);
        return NO;
    }
    
    // delete join table items
	sql = [self joinTableDeleteSQLForItem:obj manager:manager];
    if (sql.length > 0 && ![manager.database executeUpdate:sql, @(itemID)]) {
        NSLog(@"Error deleting join table items: %@", manager.database.lastErrorMessage);
        return NO;
    }
    
    // delete object
    sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE id = %ld", tableName, (long)itemID];
    if (![manager.database executeUpdate:sql, @(itemID)]) {
        NSLog(@"Error deleting object: %@", manager.database.lastErrorMessage);
        return NO;
    }
    
    return YES;
}

+ (BOOL)deleteObjects:(NSArray *)objects
{
    DBTableRepresentation *obj = objects.firstObject;
    if (obj == nil) {
        NSLog(@"No objects in array passed into %s", __PRETTY_FUNCTION__);
        return YES;
    }
    
    DBManager *manager = obj->_manager;

    BOOL success = [[manager database] beginTransaction];
    if (!success) {
        NSLog(@"Failed to begin transaction in %s with error: %@", __PRETTY_FUNCTION__, [manager database].lastErrorMessage);
        return NO;
    }

    NSMutableArray *idArray = [NSMutableArray new];
    [objects enumerateObjectsUsingBlock:^(DBTableRepresentation *item, NSUInteger idx, BOOL *stop) {
        if ([item isKindOfClass:[self class]]) {
            [idArray addObject:[@(item.itemID) stringValue]];
        }
    }];
    
    if (idArray.count != objects.count) {
        NSLog(@"Items of a different class were passed in to the %@ deleteObjects method", NSStringFromClass(self));
        return NO;
    }
    
    NSMutableArray *sqlArray = [NSMutableArray new];
    NSString *tableName = [obj tableName];
    
    [sqlArray addObject:[NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ IN (%@)",tableName, manager.idColumnName, [idArray componentsJoinedByString:@","]]];

    [objects enumerateObjectsUsingBlock:^(DBTableRepresentation *item, NSUInteger idx, BOOL *stop) {
        NSString *sql = [self childDeleteSQLForItem:item manager:manager];
        if (sql.length > 0) {
            [sqlArray addObject:sql];
        }
    }];
    

    [objects enumerateObjectsUsingBlock:^(DBTableRepresentation *item, NSUInteger idx, BOOL *stop) {
        NSString *sql = [self joinTableDeleteSQLForItem:item manager:manager];
        if (sql.length > 0) {
            [sqlArray addObject:sql];
        }
    }];

    if (![[manager database] executeStatements:[sqlArray componentsJoinedByString:@";"]]) {
        NSLog(@"Error executing statements in %s: %@", __PRETTY_FUNCTION__, [manager database].lastErrorMessage);
        [[manager database] rollback];
        return NO;
    }
    
    [[manager database] commit];
    
    return YES;
}


#pragma mark - Saving

- (void)postSaveAction
{
	// let subclasses override if desired
}

- (BOOL)saveToDB
{
	BOOL success = NO;
	NSError *error = nil;
	
	if (self.itemID == 0) {
		success = [self insertIntoTable:&error];
	}
	
	else {
		success = [self updateInTable:&error];
	}
	
	if (success) {
		_isDirty = NO;
	}
	
	[self postSaveAction];
	
	return success;
}

- (void)queueSaveToDBWithCompletionBlock:(void(^)(BOOL success, NSError *error))completion
{
	BOOL success = NO;
	NSError *error = nil;
	
	if (self.itemID == 0) {
		success = [self insertIntoTable:&error];
	}
	
	else {
		success = [self updateInTable:&error];
	}
	
	if (success) {
		_isDirty = NO;
	}
	
	if (completion != nil) {
		completion(success, error);
	}
}

#pragma mark - Methods available to override

// Override this method in subclasses with the name of the table as it is stored in your database
// if it is not the corresponding subclass's name without the class prefix
+ (NSString *)overriddenTableName
{
    return nil;
}

// Override this method in subclasses where you want to ensure specific behaviors
// or assign database table attributes
+ (NSDictionary *)tableAttributes
{
    return @{};
}

// Override this method in subclasses where you want to change the '<property>_id' naming
// scheme DBBuilder automatically applies to DBTableRepresentation class properties
+ (NSDictionary *)overriddenColumnNames
{
    return @{};
}

// override this method in subclasses for more refined equality checking
- (BOOL)isEqual:(DBTableRepresentation *)otherTable
{
    if (![otherTable isKindOfClass:[self class]]) {
        return NO;
    }
    
    return otherTable.itemID == self.itemID;
}

// override this method in subclasses if you want to change the name of a class in the database table
- (NSString *)tableName
{
	NSString *className = NSStringFromClass([self class]);
	NSString *tableName = [className substringFromIndex:_manager.classPrefix.length];
	return [tableName lowercaseString];
}

#pragma mark - Mark Dirty Flag

- (void)makeDirty
{
	_isDirty = YES;
}

- (void)makeClean
{
	_isDirty = NO;
}


#pragma mark Utilities

- (NSArray *)arrayAttributeDefinitionForClass:(NSString *)className shouldCascadeDelete:(BOOL)shouldCascadeDelete
{
    NSString *separatorAndClassName = [NSString stringWithFormat:@"%@%@", kAttributeSeparatorKey, className];
    NSMutableArray *outArray = [@[[kJoinTableMappingAttributeKey stringByAppendingString:separatorAndClassName]] mutableCopy];
    if (shouldCascadeDelete) {
        [outArray addObject:kCascadingArrayDeletionAttributeKey];
    }
    
    return [outArray copy];
}

- (BOOL)isDBTableRepresentationClass
{
    return YES;
}

/**********************************************
 
 METHODS BELOW THIS POINT ARE USED BY DBBUILDER CLASSES, AND SHOULD NOT BE CALLED FROM USER CODE
 
***********************************************/

#pragma mark - INTERNAL METHODS

#pragma mark - Query Support

+ (NSString *)sqlStringWithOptions:(NSDictionary *)options manager:(DBManager *)manager
{
    id obj;
    NSArray *columnNames;
    obj = options[kQueryColumnsKey];
    if ([obj isKindOfClass:[NSString class]]) {
        columnNames = @[obj];
    } else if ([obj isKindOfClass:[NSArray class]]) {
        columnNames = obj;
    }
    
    NSArray *conditions;
    obj = options[kQueryConditionsKey];
    if ([obj isKindOfClass:[NSString class]]) {
        conditions = @[obj];
    } else if ([obj isKindOfClass:[NSArray class]]) {
        conditions = obj;
    }
    
    NSArray *sorting;
    obj = options[kQuerySortingKey];
    if ([obj isKindOfClass:[NSString class]]) {
        sorting = @[obj];
    } else if ([obj isKindOfClass:[NSArray class]]) {
        sorting = obj;
    }
    
    NSArray *grouping;
    obj = options[kQueryGroupingKey];
    if ([obj isKindOfClass:[NSString class]]) {
        grouping = @[obj];
    } else if ([obj isKindOfClass:[NSArray class]]) {
        grouping = obj;
    }
    
    NSNumber *distinct = options[kQueryDistinctKey];
    BOOL isDistinct = distinct != nil ? distinct.boolValue : NO;
    
    DBTableRepresentation *instance = [[self alloc] initWithManager:manager];
    return [instance sqlStatementWithColumns:columnNames matchingConditions:conditions sortedBy:sorting groupedBy:grouping isDistinct:isDistinct];
}

- (NSString *)sqlStatementWithColumns:(NSArray *) columnNames matchingConditions:(NSArray *)conditions sortedBy:(NSArray *)sortArray groupedBy:(NSArray *)groupArray isDistinct:(BOOL)isDistinct
{
    NSString *columnsStr = @"*";
    if (columnNames != nil) {
        columnsStr = [columnNames componentsJoinedByString:@","];
    }
    
    NSString *distinct = (isDistinct) ? @"DISTINCT " : @"";
    
    NSString *sql = [NSString stringWithFormat:@"SELECT %@%@ FROM %@", distinct, columnsStr, [self tableName]];
    
    if (conditions != nil) {
        NSString *conditionString = [self conditionsStringFromArray:conditions];
        if (conditionString.length > 0) {
            sql = [sql stringByAppendingString:[NSString stringWithFormat:@" WHERE %@ ", conditionString]];
        }
    }
    
    if (sortArray != nil) {
        NSString *sortString = [@" ORDER BY " stringByAppendingString:[self orderStringFromArray:sortArray]];
        sql = [sql stringByAppendingString:sortString];
    }
    
    if (groupArray != nil) {
        NSString *groupString = [@" GROUP BY " stringByAppendingString:[[groupArray db_sqlEscapedArray] componentsJoinedByString:@","]];
        sql = [sql stringByAppendingString:groupString];
    }
    
    return sql;
}


- (NSArray *)arrayOfObjectsForResultSet:(FMResultSet *)result
{
    // turn the result set into an array of objects to be returned
    if (result == nil) {
        return nil;
    }
    
    NSMutableArray *outArray = [NSMutableArray array];
    while ([result next]) {
        NSDictionary *resultsDict = [result resultDictionary];
        DBTableRepresentation *instance = [[[self class] alloc] initWithManager:_manager];
        [self setValuesForItem:instance fromResultDictionary:resultsDict];
        
        [outArray addObject:instance];
    }
    
    return [outArray copy];
}


- (NSString *)orderStringFromArray:(NSArray *)orderArray
{
    // create a comma-delimited ORDER BY string
    
    if ([orderArray db_indexForCaseInsensitiveMatchOnString:@"asc"] == NSNotFound
        && [orderArray db_indexForCaseInsensitiveMatchOnString:@"desc"] == NSNotFound) {
        return [orderArray componentsJoinedByString:@","];
    }
    
    NSMutableArray *temp = [orderArray mutableCopy];
    NSString *order = nil;
    NSUInteger found = [temp db_indexForCaseInsensitiveMatchOnString:@"asc"];
    if (found != NSNotFound) {
        order = @"ASC";
        [temp removeObjectAtIndex:found];
    }
    found = [temp db_indexForCaseInsensitiveMatchOnString:@"desc"];
    if (found != NSNotFound) {
        order = @"DESC";
        [temp removeObjectAtIndex:found];
    }
    
    NSString *result = [temp componentsJoinedByString:@","];
    if (order != nil) {
        result = [NSString stringWithFormat:@"%@ %@", result, order];
    }
    
    return result;
}

- (NSString *)conditionsStringFromArray:(NSArray *)conditionsArray
{
    NSParameterAssert([conditionsArray isKindOfClass:[NSArray class]]);
    
    // create a string for the WHERE clause that comprises all condition string passed in array,
    // with "AND" or "OR" conjunction if passed in, otherwise default to "AND"
    
    if (conditionsArray.count == 0) {
        return @"";
    }
    
    NSString *conjunction = [self conjunctionForConditionsArray:conditionsArray];
    
    conditionsArray = [[self strippedConditionsArray:conditionsArray] mutableCopy];
    
    NSMutableArray *loadedArray = [NSMutableArray new];
    for (id item in conditionsArray)
    {
        // wrap strings in arrays, unless it's "AND" or "OR"
        if ([item isKindOfClass:[NSString class]]
            && ![[[item uppercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"" ] isEqualToString:@"AND"]
            && ![[[item uppercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"" ] isEqualToString:@"OR"])
        {
            [loadedArray addObject:@[item]];
        }
        else if ([item isKindOfClass:[NSArray class]])
        {
            [loadedArray addObject:item];
        }
    }
    
    return [self appendConditionsStringFromObject:loadedArray withConjunction:conjunction];
}

- (NSString *)appendConditionsStringFromObject:(NSArray *)conditionsArray withConjunction:(NSString *)conjunction
{
    // build an array of strings to output as a string joined by the conjunction parameter
    NSMutableArray *outputArray = [NSMutableArray new];
    
    if (![conditionsArray db_arrayContainsArrays])
    {
        // if none of the conditionsArray's elements are arrays, we can work directly on the conditionsArray
        // so strip out any conjunctions it contains
        conditionsArray = [self strippedConditionsArray:[conditionsArray db_rightSQLEscapedArray]];
        // join its components by the conjunction
        NSString *conditionString = [conditionsArray componentsJoinedByString:[NSString stringWithFormat:@" %@ ", conjunction]];
        // and add it to the output array
        [outputArray addObject:conditionString];
    }
    // otherwise, we need to turn any arrays into strings by calling this method recursively
    else
    {
        for (id subObject in conditionsArray) {
            // first pull out the array's conjunction
            NSString *subConjunction = [self conjunctionForConditionsArray:conditionsArray];
            // and get a new array that's stripped of that conjunction
            NSArray *strippedArray = [self strippedConditionsArray:subObject];
            // and now we can run that stripped array through this method again
            [outputArray addObject:[self appendConditionsStringFromObject:strippedArray withConjunction:subConjunction]];
        }
    }
    
    return [NSString stringWithFormat:@"(%@)", [outputArray componentsJoinedByString:conjunction]];
}

- (NSString *)conjunctionForConditionsArray:(NSArray *)conditionsArray
{
    // default to "AND"
    NSString *conjunction = @" AND ";
    // or set to "OR" if found
    NSUInteger orFind = [conditionsArray db_indexForCaseInsensitiveMatchOnString:@"or"];
    if (orFind != NSNotFound) {
        conjunction = @" OR ";
    }
    
    return conjunction;
}

- (NSArray *)strippedConditionsArray:(NSArray *)conditionsArray
{
    NSUInteger orFind = [conditionsArray db_indexForCaseInsensitiveMatchOnString:@"or"];
    NSUInteger andFind = [conditionsArray db_indexForCaseInsensitiveMatchOnString:@"and"];
    
    NSMutableArray *temp = [conditionsArray mutableCopy];
    // strip off conjunction elements
    if (andFind != NSNotFound) {
        [temp removeObjectAtIndex:andFind];
    }
    if (orFind != NSNotFound) {
        [temp removeObjectAtIndex:orFind];
    }
    
    return [temp copy];
}

- (void)loadPropertyValuesForResultSet:(FMResultSet *)rs
{
    // we're getting values from a resultset, so populate instance properties with the incoming values
    
    NSDictionary *resultsDict = [rs resultDictionary];
    [self setValuesForItem:self fromResultDictionary:resultsDict];
}

- (void)setValuesForItem:(DBTableRepresentation *)tableInstance fromResultDictionary:(NSDictionary *)resultsDict
{
    NSArray *resultKeys = [resultsDict allKeys];
    NSArray *propKeys = [self tablePropertiesToColumnMap].allKeys;
    NSUInteger instanceID = (unsigned)[resultsDict[_manager.idColumnName] integerValue];
    
    for (NSString *propertyKey in propKeys) {
        NSUInteger found = [resultKeys db_indexForCaseInsensitiveMatchOnString:propertyKey];
        
        NSUInteger typeFind = [[[self metaDataClassProperties]allKeys] db_indexForCaseInsensitiveMatchOnString:propertyKey];
        if (typeFind == NSNotFound) {
            continue;
        }
        
        NSString *typeKey = [self metaDataClassProperties][[[self metaDataClassProperties] allKeys][typeFind]];
        
        if ([NSClassFromString(typeKey) isSubclassOfClass:[DBTableRepresentation class]] || // do string comparison for unit tests...
            [NSStringFromClass([NSClassFromString(typeKey) superclass]) isEqualToString:NSStringFromClass([DBTableRepresentation class])]) {
            // it's a DBTableRepresentation subclass, so...
            NSString *columnName = [self tablePropertiesToColumnMap][propertyKey];
            if (columnName != nil) {
                // check to see if it's an ID column for a DBTableRepresentation instance
                id itemID = resultsDict[columnName];
                NSNumber *checkNumber = @0;
                if ([itemID isKindOfClass:[NSNumber class]]) {
                    checkNumber = itemID;
                }
                if (itemID == [NSNull null] || itemID == nil || checkNumber.integerValue == 0) {
                    continue;
                }
                
                // if we're trying to add the same item as a subitem, short-circuit it here to avoid a stack overflow
                if ([NSStringFromClass([self class]) isEqualToString:typeKey] // TODO: double-check that this works without further mangling
                    && (unsigned)[resultsDict[columnName] integerValue] == instanceID) {
                    [tableInstance setValue:tableInstance forKey:columnName];
                    continue;
                }
                
                DBTableRepresentation *instance = [tableInstance loadDBTableRepresentationInstanceForID:itemID withName:propertyKey];
                [tableInstance setValue:instance forKey:propertyKey];
                continue;
            }
        }
        
        if (found == NSNotFound) {
            // see if it comes from a join table
            NSString *joinName = [[NSString stringWithFormat:@"%@_%@", [self tableName], propertyKey] lowercaseString];
            if ([_manager hasJoinTableMapItem:joinName]) {
                [self loadItem:tableInstance withValuesForJoinTable:joinName fromResultsDict:resultsDict];
                continue;
            }
            
            
        } else {
            id value = resultsDict[propertyKey];
            if (value == [NSNull null] || (value == nil)) {
                continue;
            }
            
            if ([typeKey isEqualToString:@"NSDate"]) {
                if ([value isKindOfClass:[NSString class]]) {
                    NSString *dateString = value;
                    value = [dateString db_dateForSQLDateString];
                }
            }
            
            [tableInstance setValue:value forKey:propertyKey];
        }
    }
    
    if ([[resultsDict allKeys] containsObject:_manager.idColumnName]) {
        tableInstance.itemID = [resultsDict[_manager.idColumnName] integerValue];
    }
}

- (id)loadDBTableRepresentationInstanceForID:(id)itemID withName:(NSString *)propertyName
{
    NSDictionary *propertiesDict = [self metaDataClassProperties];
    NSInteger location = (int)propertyName.length - 3;
    if (location >= 0 && [[propertyName substringFromIndex:(unsigned)location] isEqualToString:kIDSuffix]) {
        propertyName = [propertyName substringToIndex:(unsigned)location];
    }
    
    NSString *type = propertiesDict[propertyName];
    NSString *table = [type substringFromIndex:_manager.classPrefix.length];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE id = ?", table];
    
    // do the select
    FMResultSet *result = [_manager.database executeQuery:sql, itemID];
    
    if (_manager.database.lastErrorCode != 0) {
        NSLog(@"Error in %s: %@", __PRETTY_FUNCTION__, _manager.database.lastErrorMessage);
        return nil;
    }
    
    Class childClass = NSClassFromString(type);
    BOOL isSubclass = [[[childClass alloc] init] isDBTableRepresentationClass];
    if (isSubclass && [result next]) {
        DBTableRepresentation *instance = [[childClass alloc]initWithManager:_manager];
        [instance buildTableDict];
        [instance loadPropertyValuesForResultSet:result];
        return instance;
    }
    
    return nil;
}


#pragma mark - Save Support

- (id)valueForTableColumn:(NSString *)columnName
{
    // get the proper name for the property to be able to access its value
    NSString *propertyName = [self tableColumnsToPropertyMap][columnName];
    
    // see if this column is a DBTableRepresentation subclass property
    NSString *propType = [self metaDataClassProperties][propertyName];
    if ([NSClassFromString(propType) isSubclassOfClass:[DBTableRepresentation class]] || // do string comparison for unit tests...
        [NSStringFromClass([NSClassFromString(propType) superclass]) isEqualToString:NSStringFromClass([DBTableRepresentation class])]) {
        DBTableRepresentation *instance = [self valueForKey:propertyName];
        return @(instance.itemID);
    }
    
    // see if we need to use a join table
    NSDictionary *joinDict = _manager.joinTableMap;
    NSDictionary *map = joinDict[columnName];
    if (map != nil) {
        return kInsertForJoinTable;
    }
    
    // otherwise return the property value
    id value = [self valueForKey:propertyName];
    
    // unless it's a date, which needs to be turned into a string
    NSString *typeKey = [self metaDataClassProperties][propertyName];
    if ([typeKey isEqualToString:@"NSDate"]) {
        // convert it to SQL date string
        NSDate *date = value;
        value = [date db_sqlDateString];
    }
    
    return value;
}

- (BOOL)insertIntoTable:(NSError **)error
{
    if ([self metaDataClassProperties] == nil) {
        [self buildTableDict];
    }
	
	NSAssert(_manager.database != nil, @"The database should not be nil");
    
    self.creationDate = [NSDate date];
    
    NSDictionary *tableColumnPropertyMap = [self tablePropertiesToColumnMap];
    
    NSMutableDictionary *paramDict = [NSMutableDictionary dictionary];
    NSArray *tableColumns = tableColumnPropertyMap.allKeys;
    NSMutableArray *paramNames = [NSMutableArray array];
    id value = nil;
    NSArray *joinInsertions = [NSMutableArray array];
    
    // create a parameter dictionary for insertion
    for (NSString *key in tableColumns) {
        if (![key isEqual:_manager.idColumnName]) {
            value = [self valueForTableColumn:tableColumnPropertyMap[key]];
            
            // if there's no value for a parameter, set the incoming value to null so it can be added to the dictionary
            if (value == nil) {
                value = [NSNull null];
            }
            
            if ([value isEqual:kInsertForJoinTable]) {
                joinInsertions = [self joinTableInsertionForColumn:tableColumnPropertyMap[key]];
            } else {
                NSString *columnName = tableColumnPropertyMap[key];
                paramDict[columnName] = value;
                [paramNames addObject:[NSString stringWithFormat:@":%@",columnName]];
            }
        }
    }
    
    // create the insertion statement
    NSString *paramList = [paramNames componentsJoinedByString:@","];
    NSString *colNames = [paramList stringByReplacingOccurrencesOfString:@":" withString:@""];
    NSString *execStatement = [NSString stringWithFormat:@"INSERT INTO %@ ( %@ ) VALUES ( %@ )", [self tableName], colNames, paramList];
    
    DBDBLog(@"Insert statement SQL: %@", execStatement);
    DBDBLog(@"Insert Params dictionary %@", paramDict);
    
    // and insert using the parameter dictionary
    BOOL success = [_manager.database executeUpdate:execStatement withParameterDictionary:paramDict];
    
    if ([_manager.database lastErrorCode] != 0) {
		NSError *lastError = [_manager.database lastError];
		if (error != nil) {
			*error = lastError;
		}
        NSLog(@"Error in %s: %d — %@",__PRETTY_FUNCTION__, [_manager.database lastErrorCode], [_manager.database lastErrorMessage]);
        if (!success) {
            return NO;
        }
    }
    
    self.itemID = (int)[_manager.database lastInsertRowId];
    
    return  [self saveJoinInsertions:joinInsertions];
}

- (BOOL)updateInTable:(NSError **)error
{
    if ([self metaDataClassProperties] == nil) {
        [self buildTableDict];
    }
    
	NSAssert(_manager.database != nil, @"The database should not be nil");
	
    NSDictionary *tableColumnPropertyMap = [self tablePropertiesToColumnMap];
    
    self.modificationDate = [NSDate date];
    
    NSArray *tableColumns = tableColumnPropertyMap.allKeys;
    NSMutableArray *statementsArr = [NSMutableArray array];
    NSString *execStatement = [NSString stringWithFormat:@"UPDATE %@ SET ", [self tableName]];
    NSMutableArray *valuesArray = [NSMutableArray new];
    NSMutableArray *joinInsertions = [NSMutableArray new];
    
    for (NSString *key in tableColumns) {
        if (![key isEqual:_manager.idColumnName]) {
            NSString *columnName = tableColumnPropertyMap[key];
            NSString *statement = [NSString stringWithFormat:@"%@ = ?", columnName];
            
            id value = nil;
            @try {
                value = [self valueForTableColumn:tableColumnPropertyMap[key]];
            }
            @catch (NSException *exception) {
                //
            }
            if ([value isEqual:kInsertForJoinTable]) {
                [joinInsertions addObjectsFromArray:[self joinTableInsertionForColumn:tableColumnPropertyMap[key]]];
            }
            
            if (value != nil && ![value isEqual:kInsertForJoinTable]) {
                [valuesArray addObject: value];
                [statementsArr addObject: statement];
            }
        }
    }
    
    // add id
    [valuesArray addObject:[NSNumber numberWithInteger:self.itemID]];
    
    NSString *whereStr = [NSString stringWithFormat:@"WHERE %@ = ?", _manager.idColumnName];
    execStatement = [execStatement stringByAppendingFormat:@"%@ %@", [statementsArr componentsJoinedByString:@","], whereStr];
    
    DBDBLog(@"Update SQL statement: %@", execStatement);
    DBDBLog(@"Update values: %@", valuesArray);
    
    BOOL success = [_manager.database executeUpdate:execStatement withArgumentsInArray:valuesArray];
    
    if ([_manager.database lastErrorCode] != 0) {
		NSError *lastError = [_manager.database lastError];
		if (error != nil) {
			*error = lastError;
		}
        NSLog(@"Error in %s: %d — %@",__PRETTY_FUNCTION__, [_manager.database lastErrorCode], [_manager.database lastErrorMessage]);
        if (!success) {
            return NO;
        }
    }
    
    return  [self saveJoinInsertions:joinInsertions];
}

- (NSDictionary *)mapTableColumnsToProperties
{
    NSMutableDictionary *outDict = [NSMutableDictionary new];
    NSArray *columnsArray = [self tableColumnNames];
    
    NSArray *propertiesArray = [self metaDataClassProperties].allKeys;
    NSArray *mapsArray = [_manager joinMapsForClassName:NSStringFromClass([self class])];
    for (NSString *propertyKey in propertiesArray) {
        NSUInteger found = [columnsArray db_indexForCaseInsensitiveMatchOnString:propertyKey];
        if (found == NSNotFound) {
            found = [columnsArray db_indexForCaseInsensitiveMatchOnString:[propertyKey stringByAppendingString:kIDSuffix]];
            if (found == NSNotFound) {
                continue;
            }
        }
        
        NSString *typeKey = [self metaDataClassProperties][propertyKey];
        // remove array properties
        if ([typeKey isEqualToString:@"NSArray"]) {
            continue;
        }
        // remove properties marked "do not persist"
        if ([self metaDataTableAttributes][propertyKey] != nil &&
            [[self metaDataTableAttributes][propertyKey] indexOfObject:kDoNotPersistAttributeKey] != NSNotFound) {
            continue;
        }
        
        NSString *columnName = columnsArray[found];
        
        // add DBTableRepresentation subclasses
        if ([NSClassFromString(typeKey) isSubclassOfClass:[DBTableRepresentation class]] || // do string comparison for unit tests...
            [NSStringFromClass([NSClassFromString(typeKey) superclass]) isEqualToString:NSStringFromClass([DBTableRepresentation class])]) {
            if ([self tableColumnsArray][propertyKey] == nil) {
                outDict[propertyKey] = [propertyKey stringByAppendingString:kIDSuffix];
            } else {
                outDict[propertyKey] = columnName;
            }
            
        } else {
            // don't need to change anything
            outDict[propertyKey] = columnName;
        }
    }
    
    for (NSDictionary *mapDict in mapsArray) {
        outDict[mapDict[kPropertyNameKey]] = [NSString stringWithFormat:@"%@_%@", mapDict[kTableNameKey], mapDict[kPropertyNameKey]];
    }
	
	// map any column names overridden in subclass
	NSDictionary * columnMap = [[self class] overriddenColumnNames];
	for (NSString *key in columnMap.allKeys) {
		if ([propertiesArray indexOfObject:key] != NSNotFound) {
			outDict[key] = columnMap[key];
		}
	}
    
    return [outDict copy];
}

- (BOOL)saveJoinInsertions:(NSArray *)joinInsertions
{
    if (joinInsertions.count > 0) {
        BOOL success = YES;
        
        for (unsigned int i = 0; i < joinInsertions.count; i++) {
            NSString *execStatement = joinInsertions[i];
            execStatement = [execStatement stringByReplacingOccurrencesOfString:kItemIDForInserts withString:[NSString stringWithFormat:@"%ld", (long)self.itemID]];
            
            DBDBLog(@"Join table save statement: %@", execStatement);
            
            if (![_manager.database executeUpdate:execStatement]) {
                success = success & NO;
            }
            
            if ([_manager.database lastErrorCode] != 0) {
                NSLog(@"Error in %s: %d — %@",__PRETTY_FUNCTION__, [_manager.database lastErrorCode], [_manager.database lastErrorMessage]);
            }
        }
        
        return success;
    }
    
    return YES;
}

#pragma mark - Deletion Support

+ (NSString *)childDeleteSQLForItem:(DBTableRepresentation *)tableInstance manager:(DBManager *)manager
{
    NSMutableArray *sqlArray = [NSMutableArray new];
    NSDictionary *propertiesDict = [ObjCClassUtil classPropsFor:self];
    for (NSString *key in propertiesDict) {
        id value = propertiesDict[key];
        if ([NSClassFromString(value) isSubclassOfClass:[DBTableRepresentation class]]) {
            DBTableRepresentation *child = [tableInstance valueForKey:key];
            if (child != nil) {
                NSInteger childID = child.itemID;
                NSString *tableName = [child tableName];
                if (tableName == nil) {
                    NSLog(@"Error deleting object. Couldn't access table name.");
                    continue;
                }
                
                [sqlArray addObject:[NSString stringWithFormat:@"DELETE FROM %@ WHERE id = %ld", tableName, (long)childID]];
            }
        }
    }
    
    return [sqlArray componentsJoinedByString:@":"];
}

+ (NSString *)joinTableDeleteSQLForItem:(DBTableRepresentation *)obj manager:(DBManager *)manager
{
    NSMutableArray *sqlArray = [NSMutableArray new];
    NSArray *joinAttributes = [manager joinMapsForClassName:NSStringFromClass([obj class])];
    if (joinAttributes != nil) {
        for (NSDictionary *joinDict in joinAttributes) {
            NSString *propertyName = joinDict[kPropertyNameKey];
            NSString *joinTableName = [NSString stringWithFormat:@"%@_%@", joinDict[kTableNameKey], propertyName];
            NSInteger itemID = obj.itemID;
            
            // delete references from join table
            [sqlArray addObject:[NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = %ld", joinTableName, joinDict[kTableIDKey], (long)itemID]];
            
            NSDictionary *attributesDict = [obj metaDataTableAttributes];
            if ([attributesDict[propertyName] indexOfObject:kCascadingArrayDeletionAttributeKey] != NSNotFound) {
                // delete objects that array members reference
                // start by getting IDs of related items
                NSMutableArray *arrayReferenceIDs = [NSMutableArray new];
                NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = %ld", joinDict[kJoinIDKey],joinTableName, joinDict[kTableIDKey], (long)itemID];
                FMResultSet *result = [[manager database]executeQuery:sql];
                while ([result next]) {
                    NSString *arrayItemID = [[result resultDictionary][joinDict[kJoinIDKey]] stringValue];
                    if (arrayItemID != nil) {
                        [arrayReferenceIDs addObject:arrayItemID];
                    }
                }
                // create delete statements for the related objects
                if (arrayReferenceIDs.count > 0) {
                    [sqlArray addObject:[NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ IN (%@)",[joinDict[kJoinClassKey] stringByReplacingOccurrencesOfString:manager.classPrefix withString:@""], manager.idColumnName, [arrayReferenceIDs componentsJoinedByString:@","]]];
                }
            }
        }
    }
    
    return [sqlArray componentsJoinedByString:@";"];
}


#pragma mark - Join Table Support

- (NSArray *)joinTableInsertionForColumn:(NSString *)columnName
{
	NSDictionary *mapDict = _manager.joinTableMap[columnName];
	NSString *tableName = mapDict[kTableNameKey];
	NSArray *objects = [self valueForKey:mapDict[kPropertyNameKey]];
	NSMutableArray *sqlArray = [NSMutableArray arrayWithCapacity:objects.count + 1];
	[sqlArray addObject:[NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = %@", columnName, [tableName stringByAppendingString:kIDSuffix], kItemIDForInserts]];
	
	for (id obj in objects) {
        NSString *insertString;
		if ([obj isKindOfClass:[DBTableRepresentation class]]) {
            DBTableRepresentation *item = (DBTableRepresentation *)obj;
            if (item.itemID > 0) {
                insertString = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@) VALUES (%@, %ld)", columnName, mapDict[kTableIDKey], mapDict[kJoinIDKey], kItemIDForInserts, (long)item.itemID];
            }
        } else {
            if ([obj isKindOfClass:[NSString class]]) {
                insertString = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@) VALUES (%@, %@)", columnName, mapDict[kTableIDKey], mapDict[kJoinIDKey], kItemIDForInserts, [obj db_sqlify]];
            } else {
                insertString = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@) VALUES (%@, %@)", columnName, mapDict[kTableIDKey], mapDict[kJoinIDKey], kItemIDForInserts, [obj stringValue]];
            }
        }

        if (insertString.length > 0) {
            [sqlArray addObject:insertString];
        }
	}
	
	return sqlArray;
}

- (NSString *)joinTableCreateStringForTableName:(NSString *)tableName
{
    NSDictionary *map = [_manager joinMapForTableName:tableName];
    if (map == nil) {
        NSLog(@"Error in %s: '%@' has not been mapped as a join table", __PRETTY_FUNCTION__, tableName);
        return nil;
    }
    
    NSUInteger location = [tableName rangeOfString:@"_"].location;
    if (location > tableName.length - 2) {
        NSLog(@"Error in %s: '%@' does not appear to be a correct mapping string", __PRETTY_FUNCTION__, tableName);
        return nil;
    }
    
    NSString *createString = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@_%@ (id Integer PRIMARY KEY AUTOINCREMENT, creationDate DateTimeStamp, modificationDate DateTimeStamp, %@ Integer, %@ Integer)", map[kTableNameKey], map[kPropertyNameKey],map[kTableIDKey], map[kJoinIDKey]];
    
    return createString;
}

- (void)loadItem:(DBTableRepresentation *)tableInstance withValuesForJoinTable:(NSString *)table fromResultsDict:(NSDictionary *) resultsDict
{
    // get data for a property that requires a join table (i.e. NSArray mapped to a join)
    NSDictionary *map = [_manager joinMapForTableName:table];
    NSAssert(map != nil, @"The join map should not be nil.");
    NSString *joinIDColName = map[kJoinIDKey];
    NSString *tableID = map[kTableIDKey];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = %@", joinIDColName, table, tableID, resultsDict[@"id"]];
    
    FMResultSet *rs = [_manager.database executeQuery:sql];
    if (_manager.database.lastErrorCode != 0) {
        NSLog(@"Error in %s: %@", __PRETTY_FUNCTION__, _manager.database.lastErrorMessage);
        return;
    }
    
    NSMutableArray *idArray = [NSMutableArray array];
    while ([rs next]) {
        [idArray addObject:[rs resultDictionary][joinIDColName]];
    }
    
    if (idArray.count == 0) {
        return;
    }
    
    NSString *joinClassName = map[kJoinClassKey];
    Class joinClass = NSClassFromString(joinClassName);
    
    if ([[joinClass alloc] isKindOfClass:[DBTableRepresentation class]]) {
        // need to look up the items by id from their table
        NSString *idsToRequest = [idArray componentsJoinedByString:@","];
        sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE id IN (%@)", [joinIDColName stringByReplacingOccurrencesOfString:kIDSuffix withString:@""], idsToRequest];
        DBDBLog(@"SQL: %@", sql);
        rs = [_manager.database executeQuery:sql];
        if (_manager.database.lastErrorCode != 0) {
            NSLog(@"Error in %s: %@", __PRETTY_FUNCTION__, _manager.database.lastErrorMessage);
            return;
        }
        
        // select from associated table where joinID IN join_id column
        NSMutableArray * arrayOfItems = [NSMutableArray array];
        
        while ([rs next]) {
            DBTableRepresentation *instance = [[joinClass alloc]initWithManager:_manager];
            [instance buildTableDict];
            [instance loadPropertyValuesForResultSet:rs];
            [arrayOfItems addObject:instance];
        }
        
        [tableInstance setValue:arrayOfItems forKey:map[kPropertyNameKey]];
        
    } else {
        // the "idArray" contains the raw values we want
        [tableInstance setValue:idArray forKey:map[kPropertyNameKey]];
    }
}


#pragma mark - Meta Data Access

- (NSDictionary *)propertiesCache
{
    NSDictionary *metaData = _manager.allTablesPropertiesCache;
    NSString *className = NSStringFromClass([self class]);
    return metaData[className];
}

- (NSDictionary *)metaDataClassProperties
{
	NSDictionary *cache = self.propertiesCache;
	return cache[kClassPropertiesDictKey];
}

- (NSDictionary *)metaDataTableAttributes
{
	NSDictionary *cache = self.propertiesCache;
	return cache[kClassAttributesKey];
}

- (NSDictionary *)tableColumnsArray
{
	NSDictionary *cache = self.propertiesCache;
	return cache[kColumnRemapDictKey];
}

- (NSDictionary *)tablePropertiesToColumnMap
{
	NSDictionary *cache = self.propertiesCache;
	return cache[kTablePropertyToColumnMap];
}

- (NSDictionary *)tableColumnsToPropertyMap
{
    NSDictionary *cache = self.propertiesCache;
    return cache[kTableColumnToPropertyMap];
}

#pragma mark - Create Class Meta-data Maps

- (void)buildTableDict
{
    if ([_manager classIsPrepared:[self class]]) {
        return;
    }
    
	NSDictionary *cache = _manager.allTablesPropertiesCache;
	NSString *className = NSStringFromClass([self class]);
	NSDictionary *meta = cache[className];
	
	if (meta[kClassPropertiesDictKey] == nil) {
		NSDictionary *propertiesDict = [ObjCClassUtil classPropsFor:[self class]];
		[_manager setProperties:propertiesDict forClass:[self class]];
	}
	
	if (meta[kClassAttributesKey] == nil) {
		NSDictionary *attributesDict = [[self class] tableAttributes];
		NSMutableDictionary *temp = [attributesDict mutableCopy];
		for (NSString *key in attributesDict) {
			id value = attributesDict[key];
			if ([value isKindOfClass:[NSString class]]) {
				// wrap it in an array
				temp[key] = @[value];
			} else if ([value isKindOfClass:[NSArray class]]) {
				temp[key] = value;
			}
		}
		// add attribute to prevent persisting the isDirty flag
		temp[@"isDirty"] = @[kDoNotPersistAttributeKey];
        temp[@"propertiesCache"] = @[kDoNotPersistAttributeKey];
		[_manager setAttributes:[temp copy] forClass:[self class]];
	}
	
	if (meta[kColumnRemapDictKey] == nil) {
		NSDictionary *remapDict = [[self class] overriddenColumnNames];
        [_manager setColumnRemappingDict:remapDict forClass:[self class]];
	}
    
    [_manager setTableColumnsToPropertiesMap:[self mapTableColumnsToProperties] forClass:[self class]];
}

- (void)mapJoinForProperty:(NSString *)propertyName
{
	NSString *mapTable = [self mapTableNameForArrayProperty:propertyName];
	
	if (mapTable != nil) {
		if (_manager.joinTableMap == nil) {
			_manager.joinTableMap = [NSDictionary dictionary];
		}
		
		NSString *className = NSStringFromClass([self class]);
		NSString *abbrevClassName = [[className stringByReplacingOccurrencesOfString:_manager.classPrefix withString:@""] lowercaseString];
		NSString *abbrevJoinTable = [[mapTable stringByReplacingOccurrencesOfString:_manager.classPrefix withString:@""] lowercaseString];
		NSDictionary *submap = @{kClassKey : className,
								 kPropertyNameKey : propertyName,
								 kTableNameKey : abbrevClassName,
								 kTableIDKey : [abbrevClassName stringByAppendingString:kIDSuffix],
								 kJoinIDKey : [abbrevJoinTable stringByAppendingString:kIDSuffix],
								 kJoinClassKey : mapTable};
		NSString *mapKey = [NSString stringWithFormat:@"%@_%@", [[className stringByReplacingOccurrencesOfString:_manager.classPrefix withString:@""] lowercaseString],
							[propertyName lowercaseString]];
		
		NSMutableDictionary *mapDict = [_manager.joinTableMap mutableCopy];
		mapDict[mapKey] = submap;
		_manager.joinTableMap = [mapDict copy];
	}
}


- (NSString *)mapTableNameForArrayProperty:(NSString *)propertyName
{
	NSString *mapTable = nil;
	NSDictionary *attributesDict = [self metaDataTableAttributes];
	NSArray *mapArray = attributesDict[propertyName];
	for (NSString *mapCheck in mapArray) {
		if (mapCheck != nil && [[mapCheck substringToIndex:kJoinTableMappingAttributeKey.length] isEqualToString:kJoinTableMappingAttributeKey]) {
			NSUInteger location = [mapCheck rangeOfString:kAttributeSeparatorKey].location;
			if (mapCheck.length > location) {
				mapTable = [mapCheck substringFromIndex:location + 1];
				break;
			}
		}
	}
	
	return mapTable;
}

- (NSArray *)tableColumnNames
{
    NSMutableArray *outArray = [NSMutableArray new];
    
    static NSCharacterSet *parensSet;
    parensSet = [NSCharacterSet characterSetWithCharactersInString:@"()"];
    NSString *sql = [self tableCreationString];
    NSArray *components = [sql componentsSeparatedByString:@","];
    for (NSString *component in components) {
        NSString *columnAndType = [[component  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByTrimmingCharactersInSet:parensSet];
        NSArray *pair = [columnAndType componentsSeparatedByString:@" "];
        if (pair.firstObject != nil) {
            [outArray addObject:pair.firstObject];
        }
    }
    
    // trim off "Create"
    [outArray removeObjectAtIndex:0];

    return [outArray copy];
}


- (void)addTableTypesToDictionary:(NSMutableDictionary *)dictionary
{
    NSString *sql = [self tableCreationString];
	if (sql == nil) {
		return;
	}
	
    static NSCharacterSet *parensSet;
    parensSet = [NSCharacterSet characterSetWithCharactersInString:@"()"];
    NSMutableArray *components = [[sql componentsSeparatedByString:@","] mutableCopy];
    for (unsigned int i = 1; i < components.count; i++) {
        NSString *component = components[i];
        component = [[component  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByTrimmingCharactersInSet:parensSet];
        NSArray *pair = [component componentsSeparatedByString:@" "];
        NSUInteger found = [[self tableColumnsToPropertyMap].allKeys db_indexForCaseInsensitiveMatchOnString:pair[0]];
        if (found != NSNotFound) {
            NSString *key = [self tableColumnsToPropertyMap][[self tableColumnsToPropertyMap].allKeys[found]];
            NSString *type = pair[1];
            dictionary[key] = type;
        }
    }
}

- (void)cacheDBProperties
{
    NSAssert(![NSStringFromClass([self class]) containsString:@"."], @"It looks you've subclassed DBTableRepresentation with a Swift class, which is not allowed");
	NSAssert(_manager.filePath != nil, @"The DBManager instance file path has not been set.");
    NSAssert(_manager.classPrefix.length > 0, @"The classPrefix property has not been defined");
#if DEBUG
    NSString *className = NSStringFromClass([self class]);
    NSAssert([[className substringToIndex:_manager.classPrefix.length] isEqualToString:_manager.classPrefix],
             @"The prefix for the %@ class does not match '%@' defined with the classPrefix property value", className, _manager.classPrefix);
#endif
	NSAssert(_manager.database != nil, @"database should not be nil in %s", __PRETTY_FUNCTION__);
	
    if ([_manager classIsPrepared:[self class]]) {
        return;
    }
    
	NSDictionary *cache = _manager.allTablesPropertiesCache;
	if (cache == nil || cache[NSStringFromClass([self class])] == nil) {
		[self buildTableDict];
		[self verifyTableWithRetry:NO];
	}
}


#pragma mark - Validity Checking/Repair

- (BOOL)verifyTableWithRetry:(BOOL)retry
{
	if (_manager.database == nil) {
		NSLog(@"Error verifying table: Database is nil.");
		return false;
	}
	
	if (![_manager.database tableExists:[self tableName]]) {
		if (!retry) {
			NSString *sql = [self tableCreationString];
			if (sql == nil) {
				return NO;
			}
			
			[_manager.database executeUpdate:sql];
			DBDBLog(@"Creation string: %@", sql);
			return [self verifyTableWithRetry:YES];
		}
	}
	
    [self checkJoinTables];
	[self checkTableColumns];

	return YES;
}

- (void)checkJoinTables
{
    NSDictionary *map = _manager.joinTableMap;
    
    if (map == nil) {
        return;
    }
    
    for (NSString *mapItem in map) {
        NSString *sql = [self joinTableCreateStringForTableName:mapItem];
        
        if (sql != nil) {
            [_manager.database executeUpdate:sql];
        }
        
        // update won't change table's column names, so check to make sure join column exists
        NSString *createString = [[_manager database] createStringForTable:mapItem manger:_manager];
        NSString *checkColumnName = map[mapItem][kJoinIDKey ];
        NSRange range = [createString rangeOfString:checkColumnName];
        if (range.length == 0) {
            sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD %@ Text",mapItem, checkColumnName];
            NSLog(@"Updating %@ table with: '%@'", mapItem, sql);
            [_manager.database executeUpdate:sql];
        }
    }
}


- (void)checkTableColumns
{
	NSAssert([self tableName] != nil, @"Table name is nil in checkTableNames");
	NSAssert(_manager.database != nil, @"Database is nil in checkTableNames");
	
	if ([self metaDataClassProperties] == nil) {
		[self buildTableDict];
	}
	
	NSMutableDictionary *newColumnsDict = [NSMutableDictionary new];
    NSArray *propertiesArray = [[self metaDataClassProperties] allKeys];
    NSDictionary *attributes = [self metaDataTableAttributes];
    NSDictionary *tablePropertiesColumnMap = [self tablePropertiesToColumnMap];
    for (NSString *item in propertiesArray) {
        if ([attributes[item] containsObject:kDoNotPersistAttributeKey]) {
            continue;
        }
            NSString *propName = tablePropertiesColumnMap[item];
			NSAssert(propName != nil, @"Property name must not be nil");
			if (![_manager.database columnExists:propName inTableWithName:[self tableName]]) {
				BOOL dontPersist = attributes[item] != nil && [attributes[item] containsObject:kDoNotPersistAttributeKey];
				if (!dontPersist) {
					newColumnsDict[item] = propName;
				}
		}
	}
    
    if (newColumnsDict.count > 0) {
        for (NSString *column in newColumnsDict.allKeys) {
            NSString *type = [self metaDataClassProperties][column];
            NSString *columnName = newColumnsDict[column];
            // see if it's a DBTableRepresentation class we need to set an ID for
            Class itemClass = NSClassFromString(type);
            if ([itemClass isSubclassOfClass:[self class]]) {
                // set the type to Integer, which will store the ID for this item
                type = @"Integer";
            }
            
            if (type != nil) {
                // convert type to SQL type
                type = [DBTableRepresentation columnTypeForPropertyType:type];
                NSString *alterStmt = [NSString stringWithFormat:@"ALTER TABLE '%@' ADD COLUMN '%@' %@", [self tableName], columnName, type];
                
                if (attributes[column] != nil && [attributes[column] containsObject:kNotNullAttributeKey]) {
                    alterStmt = [alterStmt stringByAppendingString:@" NOT NULL DEFAULT ''"];
                }
                
                // save it to the DB
                if (![_manager.database executeUpdate:alterStmt]) {
                    NSLog(@"Error updating table %@: %@", [self tableName], _manager.database.lastErrorMessage);
                } else {
                    // update the table meta data if it was successful
                    [self buildTableDict];
					NSLog(@"Added column for %@ to %@ table", columnName, [self tableName]);
                }
            }
        }
    }
    
    [_manager setClassIsPrepared:[self class]];
}


#pragma mark - Table Creation

+ (NSString *)columnTypeForPropertyType:(NSString *)propertyType
{
	static NSDictionary *typesDict = nil;
	if (typesDict == nil) {
		typesDict = @{@"NSString" : @"Text",
					  @"NSMutableString" : @"Text",
					  @"NSDate" : @"DateTimeStamp",
					  @"NSInteger" : @"Integer",
					  @"BOOL" : @"Boolean",
					  @"int" : @"Integer",
					  @"int8_t" : @"Integer",
					  @"int16_t" : @"Integer",
					  @"int32_t" : @"Integer",
					  @"int64_t" : @"Integer",
					  @"unsigned int" : @"Integer",
					  @"uint" : @"Integer",
					  @"UInt16" : @"Integer",
					  @"uint16_t" : @"Integer",
					  @"integer_t" : @"Integer",
					  @"UInt32" : @"Integer",
					  @"uint32_t" : @"Integer",
					  @"UInt64" : @"Integer",
					  @"uint64_t" : @"Integer",
					  @"NSDecimalNumber" : @"Decimal",
					  @"NSNumber" : @"Numeric",
					  @"NSData" : @"BLOB"
					  };
	}
	
	if (typesDict[propertyType] != nil) {
		return typesDict[propertyType];
	}
	
	return propertyType;
}

- (NSArray *)allowedTypes
{
	static NSArray *allowedTypes = nil;
	if (allowedTypes == nil) {
		allowedTypes = @[@"Boolean",@"Integer",@"float",@"double",@"Numeric",@"DateTimeStamp",@"Decimal",@"Text"];
	}
	
	return allowedTypes;
}

- (NSString *)tableCreationString
{
	NSDictionary *cache = _manager.allTablesPropertiesCache;
	
	if (cache == nil) {
		[self buildTableDict];
	}
    
    NSString *className = NSStringFromClass([self class]);
	cache = cache[className];
	if (cache == nil) {
		return nil;
	}
	
	NSDictionary *attributesDict = [self metaDataTableAttributes];
	NSDictionary *propsDict = cache[kClassPropertiesDictKey];
	NSMutableArray *qArray = [NSMutableArray arrayWithCapacity:propsDict.count];
	NSArray *attributesArray;
	for (NSString * propertyName in propsDict) {
        attributesArray = nil;
		if (![[propertyName lowercaseString] isEqualToString:_manager.idColumnName] &&
			![[propertyName lowercaseString] isEqualToString:@"creationdate"] &&
			![[propertyName lowercaseString] isEqualToString:@"modificationdate"]) {
            
            if (attributesDict[propertyName] != nil) {
				attributesArray = [DBTableRepresentation arrayForObject:attributesDict[propertyName]];
			}
            
			if ([attributesArray containsObject:kDoNotPersistAttributeKey]) {
                continue;
            }
            
            NSString *type = [[self class] columnTypeForPropertyType:propsDict[propertyName]];
            
            // allow arrays of types SQLite can handle and DBTableRepresentation subclasses
            if ([type isEqualToString:@"NSArray"]) {
				[self mapJoinForProperty:propertyName];
                NSString *joinName = [[NSString stringWithFormat:@"%@_%@", [self tableName], propertyName] lowercaseString];
				if ([[self allowedTypes]indexOfObject:type] == NSNotFound &&
					![NSClassFromString(type) isSubclassOfClass:[DBTableRepresentation class]]
					&& ![_manager hasJoinTableMapItem:joinName]) {
					NSLog(@"Skipped adding column for %@ in '%@' class because items of type %@ are not allowed", propertyName, [self class], type);
					continue;
				}
				
				if (![_manager classIsPrepared:[self class]]) {
					DBDBLog(@"Added column for Array property '%@'", propertyName);
				}
				
                // skip adding NSArray properties
				continue;
			}
			
			NSString *value = propertyName;
			
            Class typeClass = NSClassFromString(type);

			if ([typeClass isSubclassOfClass:[DBTableRepresentation class]] ||
                [NSStringFromClass([NSClassFromString(type) superclass]) isEqualToString:NSStringFromClass([DBTableRepresentation class])]) {
				// NOTE: String comparison above is a workaround for problem with checking subclass of class generated with NSClassFromString in unit test
				// if it's a DBTableRepresentation subclass create an Integer "id" column for this property
                value = ([self tableColumnsArray][propertyName] == nil) ?
                    [NSString stringWithFormat:@"%@%@", propertyName, kIDSuffix] :
                    [self tableColumnsArray][propertyName];
				type = @"Integer";
			}
			
			value = [NSString stringWithFormat:@"%@ %@", value, type];
			
			if (attributesArray != nil && [attributesArray count] > 0) {
				value = [value stringByAppendingString:[NSString stringWithFormat:@" %@", [attributesArray componentsJoinedByString:@" "]]];
			}
			
			[qArray addObject:value];
		}
	}
	
	NSString *createString = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id Integer PRIMARY KEY AUTOINCREMENT, creationDate DateTimeStamp, modificationDate DateTimeStamp,", self.tableName];
	createString = [createString stringByAppendingString:[qArray componentsJoinedByString:@", "]];
	createString = [createString stringByAppendingString:@")"];
	
	return createString;
}

+ (NSArray *)arrayForObject:(id)obj
{
    if ([obj isKindOfClass:[NSArray class]]) {
        return (NSArray *)obj;
    }
    
    return @[obj];
}

#pragma mark - KVC Foregiveness

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
	// swallow it
	NSLog(@"Attempting to set value on class %@ with unrecognized key: %@", [self class], key);
}

- (id)valueForUndefinedKey:(NSString *)key
{
	NSLog(@"Attempting to get value from class %@ for unrecognized key: %@", [self class], key);
	return [NSNull null];
}


@end
