//
//  DBManager.m
//
//  Created by Dennis Birch on 6/11/12.
//  Copyright (c) 2012 Dennis Birch. All rights reserved.
//

#import "DBManager.h"
#import "ObjCClassUtil.h"
#import "DBTableRepresentation.h"
#import "NSString+DBExtensions.h"

@interface DBManager ()

@property (nonatomic, assign) BOOL hasVerifiedTables;
@property (nonatomic, strong, readwrite) NSDictionary *allTablesPropertiesCache;
@property (nonatomic, strong) NSArray *preparedClasses;

@end

@implementation DBManager



#pragma mark - Singleton Support

static DBManager *sharedManager = nil;

+ (DBManager *)defaultDBManager
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedManager = [[self alloc] init];
	});
	
	return sharedManager;
}

+ (DBManager *)managerWithFilePath:(NSString *)dbFilePath
{
	DBManager *mgr = [[DBManager alloc] init];
	if (mgr) {
		mgr.filePath = dbFilePath;
		[mgr database];
	}
	
	return mgr;
}

- (void)configureWithFilePath:(NSString *)filePath classPrefix:(NSString *)classPrefix idColumnName:(NSString *)idColumnName
{
    self.filePath = filePath;
    self.classPrefix = classPrefix;
    self.idColumnName = idColumnName;
}

- (FMResultSet *)runQuery:(NSString *)query
{
    if (self.database == nil  || [query isEqualToString:@""]) {
        return nil;
    }
    
    FMResultSet *result = [[self database] executeQuery:query];
    if (result == nil) {
        NSLog(@"Error running query: %@",[[self database] lastError]);
        return nil;
    }
    
    // set up result set ready for first read
    [result next];
    return result;
}


- (NSUInteger)countForTable:(NSString *)tableName
{
    NSString *query = @"SELECT COUNT(*) FROM";
    query = [NSString stringWithFormat:@"%@ %@",query, tableName];
    
    FMResultSet *result = [self runQuery:query];
    if (result == nil) {
        return 0;
    }
    return (unsigned)[result intForColumnIndex:0];
}


- (FMResultSet *)recordForTable:(NSString *)tableName row:(NSInteger)row
{
    NSString *query = @"SELECT * FROM";
    query = [NSString stringWithFormat:@"%@ %@",query, [tableName db_sqlify]];
    
    FMResultSet *result = [self runQuery:query];
    if (result == nil) {
        return nil;
    }
    
    NSInteger n = 1;
    while (n < row) {
        if ([result next]) {
            n++;
        }
    }
    
    return result;
}




// ********************************************
// Internally used methods
// ********************************************

- (void)setFilePath:(NSString *)filePath
{
    NSAssert((filePath != nil), @"File path should not be nil in %s", __PRETTY_FUNCTION__);
    
    _filePath = filePath;
    
	if (_database == nil) {
        
			_database = [FMDatabase databaseWithPath:self.filePath];
		
		if (![_database open])
		{
			_database = nil;
			return;
		}
	}
}

#pragma mark - database Access

- (FMDatabase *)database
{
    if (self.allTablesPropertiesCache == nil) {
        self.allTablesPropertiesCache = [NSDictionary new];
    }
	
	return _database;
}

/**********************************************

 METHODS BELOW THIS POINT ARE USED BY DBBUILDER CLASSES, AND SHOULD NOT BE USED FOR OTHER PURPOSES
 
***********************************************/
#pragma mark - Internal Use

- (void)dealloc
{
    [self.database close];
}

#pragma mark - Setters for Meta Data

- (NSDictionary *)metaDataForTable:(NSString *)prefixedTableName
{
	NSDictionary *meta = self.allTablesPropertiesCache[prefixedTableName];
	if (meta == nil) {
		meta = [NSDictionary new];
	}
	
	return meta;
}

- (void)setProperties:(NSDictionary *)propertiesDict forClass:(Class)class
{
	if (propertiesDict == nil) {
		return;
	}
	
	NSString *tableName = NSStringFromClass(class);
	NSMutableDictionary *meta = [[self metaDataForTable:tableName] mutableCopy];
	meta[kClassPropertiesDictKey] = propertiesDict;
	NSMutableDictionary *allData = [self.allTablesPropertiesCache mutableCopy];
	allData[tableName] = [meta copy];
	self.allTablesPropertiesCache = [allData copy];
}

- (void)setTableColumnsToPropertiesMap:(NSDictionary *)mapDict forClass:(Class)class
{
	if (mapDict == nil) {
		return;
	}
	
	NSString *tableName = NSStringFromClass(class);
	NSMutableDictionary *meta = [[self metaDataForTable:tableName] mutableCopy];
	meta[kTablePropertyToColumnMap] = mapDict;
    
    // make an inverse map
    NSMutableDictionary *columnToPropertyMap = [NSMutableDictionary new];
    for (NSString *key in mapDict.allKeys) {
        NSString *value = mapDict[key];
        columnToPropertyMap[value] = key;
    }
    meta[kTableColumnToPropertyMap] = columnToPropertyMap;
    
	NSMutableDictionary *allData = [self.allTablesPropertiesCache mutableCopy];
	allData[tableName] = [meta copy];
	self.allTablesPropertiesCache = [allData copy];
}


- (void)setAttributes:(NSDictionary *)attributesDict forClass:(Class)class
{
	if (attributesDict == nil) {
		return;
	}
	
	NSString *tableName = NSStringFromClass(class);
	NSMutableDictionary *meta = [[self metaDataForTable:tableName] mutableCopy];
	meta[kClassAttributesKey] = attributesDict;
	NSMutableDictionary *allData = [self.allTablesPropertiesCache mutableCopy];
	allData[tableName] = [meta copy];
	self.allTablesPropertiesCache = [allData copy];
}

- (void)setColumnRemappingDict:(NSDictionary *)remappingDict forClass:(Class)class
{
	if (remappingDict == nil) {
		return;
	}

	NSString *tableName = NSStringFromClass(class);
	NSMutableDictionary *meta = [[self metaDataForTable:tableName] mutableCopy];
	meta[kColumnRemapDictKey] = remappingDict;
	NSMutableDictionary *allData = [self.allTablesPropertiesCache mutableCopy];
	allData[tableName] = [meta copy];
	self.allTablesPropertiesCache = [allData copy];
}

#pragma mark - Mark/Check Class Setup

- (void)setClassIsPrepared:(Class)class
{
    if (self.preparedClasses == nil) {
        self.preparedClasses = [NSArray array];
    }
    
    if ([self.preparedClasses indexOfObject:class] != NSNotFound) {
        return;
    }
    
    NSMutableArray *temp = [self.preparedClasses mutableCopy];
    [temp addObject:class];
    self.preparedClasses = [temp copy];
}

- (BOOL)classIsPrepared:(Class)class
{
    if (self.preparedClasses == nil) {
        return NO;
    }
    
    return [self.preparedClasses indexOfObject:class] != NSNotFound;
}

#pragma mark - Handle Join Table Map

- (BOOL)hasJoinTableMapItem:(NSString *)joinTableName
{
    return self.joinTableMap[joinTableName] != nil;
}


- (NSDictionary *)joinMapForTableName:(NSString *)joinTableName
{
    return self.joinTableMap[joinTableName];
}

- (NSArray *)joinMapsForClassName:(NSString *)className
{
	NSMutableArray *outArray = [NSMutableArray array];
	
	for (NSString *key in [self.joinTableMap allKeys]) {
		NSDictionary *mapDict = self.joinTableMap[key];
		if ([mapDict[kClassKey] isEqualToString:className]) {
			[outArray addObject:mapDict];
		}
	}
	
	return outArray;
}

@end
