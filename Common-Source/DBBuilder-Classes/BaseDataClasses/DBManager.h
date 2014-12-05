//
//  DBManager.h
//
//  Created by Dennis Birch on 6/11/12.
//
//  Copyright (c) 2012 Dennis Birch. All rights reserved.
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
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "FMDatabaseAdditions.h"
#import "FMDatabase+DBExtensions.h"
#import "DBDefines.h"

/*! An add-on to FMDB for use with SQLite databases

\b Usage
 The two main classes in FMDB are:
 
 1. DBManager - Represents a single SQLite database.  Used for top-level access to its data.
 2. DBTableRepresentation - An abstract class that maps to a database table. Subclass it to create tables, update them, and write to and read from databases, either with SQL statements or object instances.

\b Links
 
 - [FMDB on GitHub](https://github.com/ccgus/fmdb)
 - [SQLite web site](http://sqlite.org/)
 
 */


@interface DBManager : NSObject

@property (nonatomic, strong) FMDatabase *database;
@property (nonatomic, strong, readonly) NSDictionary *allTablesPropertiesCache;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *classPrefix;
@property (nonatomic, copy) NSString *idColumnName;
@property (nonatomic, strong) NSDictionary *joinTableMap;

// user-facing methods

/*!
	Method to access the default DBManager singleton.
	@returns The default DBManager singleton instance.
 */
+ (DBManager *)defaultDBManager;

/*!
	Method to access a secondary DBManager instance.
	@params	dbFilePath: A file path for the SQLite file the DBManager instance will manage.
	@returns The requested DBManager instance.
 */
+ (DBManager *)managerWithFilePath:(NSString *)dbFilePath;


/*!
	Method to set properties that are required for proper configuration of your DBManager instance.
	@params	
        filePath: A file path for the SQLite file the DBManager instance will manage. Pass in nil if you want to use an in-memory database.
        classPrefix: The prefix your DBTableRepresentation subclasses are named with. This must be at least one character long.
        idColumnName: The name used in your database tables for a unique ID primary key column.
	@returns The requested DBManager instance.
 */
- (void)configureWithFilePath:(NSString *)filePath classPrefix:(NSString *)classPrefix idColumnName:(NSString *)idColumnName;

/*!
	Method to run a database query on a DBManager instance.
	@params	query: An SQL statement to execute.
	@returns The results of running the database query.
 */
- (FMResultSet *)runQuery:(NSString *)query;

/*!
	Method to obtain the number of records in a database table.
	@params	tableName: The name of the database table whose count you want to obtain.
	@returns The count of records for that table.
 */
- (NSUInteger)countForTable:(NSString *)tableName;

/*!
	Method to obtain a FMResultSet instance representing a database table row's contents.
	@params	
        tableName: The name of the database table whose records you want to access.
        row: The row number whose contents you want to access
	@returns An FMResultSet instance with the table row's contents, or nil.
 */
- (FMResultSet *)recordForTable:(NSString *)tableName row:(NSInteger)row;

// internal methods (required by DBTableRepresentation class, using these in your own code will probably just lead to misery)

- (void)setProperties:(NSDictionary *)propertiesDict forClass:(Class)class;
- (void)setAttributes:(NSDictionary *)attributesDict forClass:(Class)class;
- (void)setColumnRemappingDict:(NSDictionary *)remappingDict forClass:(Class)class;
- (void)setTableColumnsToPropertiesMap:(NSDictionary *)mapDict forClass:(Class)class;
- (BOOL)hasJoinTableMapItem:(NSString *)joinTableName;
- (NSDictionary *)joinMapForTableName:(NSString *)joinTableName;
- (NSArray *)joinMapsForClassName:(NSString *)className;
- (void)setClassIsPrepared:(Class)class;
- (BOOL)classIsPrepared:(Class)class;

@end
