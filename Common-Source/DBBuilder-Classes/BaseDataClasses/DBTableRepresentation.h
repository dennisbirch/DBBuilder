//
//  DBTableRepresentation
//
//  Created by Dennis Birch on 6/8/12.
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
#import "DBManager.h"


/*!

 This is a semi-virtual class that you will need to subclass to use.

 Each subclass should represent a table in your SQLite database.

 This superclass offers some common properties you may want to map to table column names (and in one case need to).

- itemID maps to an ID table column which you can name as you please, but you must map that name by setting the 
    DBManager "idColumnName" property.

- creationDate is a property for saving a SQL timestamp for each table entry's creation date and time

- modificationDate is a property for saving a SQL timestamp for each table entry's last modification

 The DBTableRepresentation class offers several initializers for creating instances of your subclasses, 
 as well as convenience methods for obtaining instances, methods for saving an entire ResultSet to its 
 table as an insert or an update, and methods for deleting instances.
 

REQUIRED CONFIGURATION

Be sure to set the DBManager "dbClassPrefix" property to the correct value for your project.

Be sure to assign the correct values to the DBManager "idColumnName" property.
 
You can assign both these values, along with the file path to your SQLite file, with the 
    DBManager - configureWithFilePath: classPrefix: idColumnName: method

 \sa 
 ManagerConfiguration.h
*/
@interface DBTableRepresentation : NSObject

{
	DBManager *_manager;
}

NS_ASSUME_NONNULL_BEGIN

@property (nonatomic, assign, readonly) BOOL isDirty;
@property (nonatomic, assign, readonly) NSInteger itemID;
@property (nullable, nonatomic, strong) NSDate *creationDate;
@property (nullable, nonatomic, strong) NSDate *modificationDate;

// INITIALIZERS

/*!
 Sets up a bare instance of a DBTableRepresentation.
 @param manager
		An instance of a DBManager class, typically the defaultManager.
 @returns An instance of your DBTableRepresentation subclass ready to have its values set in code.
 */
- (instancetype)initWithManager:(DBManager *)manager;


/*!
 Sets up an instance of a DBTableRepresentation subclass based on its unique ID.
 @param itemID
		The integer value for the instance you want to load.
 @param manager.
		An instance of a DBManager class, typically the defaultManager.
 @returns An instance of your DBTableRepresentation subclass fully setup with values pulled from the database.
*/
- (instancetype)initWithID:(NSInteger)itemID manager:(DBManager *)manager;

/*!
 Sets up an instance of a DBTableRepresentation subclass with values passed in.
 @param dict
 A dictionary with values keyed to the object's property names.
 @param manager.
 An instance of a DBManager class, typically the defaultManager.
 @returns An instance of your DBTableRepresentation subclass setup with whatever values were passed in.
 */
- (instancetype)initWithDictionary:(NSDictionary *)dict manager:(DBManager *)manager;


/*!
 Convenience method to get an instance that has been saved to the database.
 @param dict
 A dictionary with values keyed to the object's property names.
 @param manager.
 An instance of a DBManager class, typically the defaultManager.
 @returns An instance of your DBTableRepresentation subclass set with values that were passed in, which have been saved to the database.
 */
+ (instancetype __nullable)savedInstanceWithValues:(NSDictionary *)values manager:(DBManager *)manager;


// ACCESSING DATA
/*!
 Convenience method to get an array of objects matching query options you pass in.
 @param options
 A dictionary with values keyed to query options constants defined in the DBDefines.h file. Options values can be either an NSString for a single value, or an NSArray for multiple values.

 These include:
 
 kQueryColumnsKey - list of columns to include in the results

 kQueryConditionsKey - list of conditions to include in the query's WHERE clause
 
 kQuerySortingKey - list of columns to sort results by; include DESC after column name for a descending sort (ascending is the default)
 
 kQueryGroupingKey - list of columns to group results by
 
 kQueryDistinctKey - boolean value to indicate whether results should only return distinct values; you can also pass in 0/1 for false/true
 
 Only options that you want to make sure are applied need to be included in the options dictionary.
 
 @param manager.
 An instance of a DBManager class, typically the defaultManager.
 @returns An NSArray of objects matching your query.
 */
+ (nullable NSArray *)objectsWithOptions:(nullable NSDictionary *) options manager:(DBManager *)manager;

/*!
 Convenience method using an FMDatabaseQueue to get an array of objects matching query options you pass in.
 @param options
		A dictionary with values keyed to query options constants defined in the DBDefines.h file. Options values can be either an NSString for a single value, or an NSArray for multiple values.
 @param manager
		An instance of a DBManager class, typically the defaultManager.
 @param completionBlock A block object to execute completion behavior on the resultsArray.
 */
+ (void)queueObjectsWithOptions:(nullable NSDictionary *)options manager:(DBManager *)manager completionBlock:(void(^)(NSArray *resultsArray, NSError *error))completion;

/*!
 Convenience method that returns the "id" column value for all records in a table
 @param manager
 An instance of a DBManager class, typically the defaultManager.
 @Returns: An NSArray with the item IDs of all the records in the table represented by the DBTableRepresentation subclass this method is run on
 */
+ (NSArray *)allIDsForTableWithManager:(DBManager *)manager;



// SAVING OBJECTS
/*!
 Saves a DBTableRepresentation instance to the database.
 @returns A boolean indicating success.
 */
- (BOOL)saveToDB;

/*!
 Stub method to allow custom post-save actions in subclasses.
 Override this method in subclasses to perform any desired action after the save action has completed.
 */
- (void)postSaveAction;

/*!
 Saves a DBTableRepresentation instance to the database on a serial queue.
 @params 
	Completion block with: 
		success - A boolean indicating successful completion
		error - An NSError passed from the FMDatabase instance
 */
- (void)queueSaveToDBWithCompletionBlock:(nullable void(^)(BOOL success, NSError *error))completion;


// DELETING OBJECTS
/*!
 This class method deletes a DBTableRepresentation object and its related entries from the database.
 @param obj The object that should be deleted.
 @returns A boolean indicating success. If the object has related entries, it will indicate failure in cases where any of them could not be deleted.
 */
+ (BOOL)deleteObject:(nullable DBTableRepresentation *)obj;


/*!
 This class method deletes an array of DBTableRepresentation objects and its related entries from the database.
 If the operation fails for any reason, the database is left in the same state it was in before attempting to delete the objects.
 @param objects An NSArray containing the objects that should be deleted.
 @returns A boolean indicating success.
 */
+(BOOL)deleteObjects:(NSArray *)objects;

/*!
 This class method lets you override the name that DBBuilder automatically creates for a
 database table. Call this method in a class implementation file and return the name you want
 DBBuilder to use for that subclass's table in the database.
 @returns The name that should be used for the class's table in the database.

 DBBuilder automatically selects database table names by removing your class prefix from the
 names of your DBTableRepresentation subclasses. For instance, if your prefix is "DBT", the
 table name for "DBTProject" becomes "project".
 Implement this method in any subclasses if you want a different name to be used,
 (perhaps you're working with a pre-defined table structure).
 For example, if DBTProject's table in the database was named "ProjectTable", you would
 return @"ProjectTable" from an implementation of this method in the DBTProject class.
*/
+ (NSString *)overriddenTableName;

/*!
 This class method allows you to set attributes for columns on a database table.
 Override this method in your subclasses to set these attributes:
 
 1) "kDoNotPersistAttributeKey" for properties you do not want saved to your database

 2) "kNotNullAttributeKey" for properties that must not be null in the database
 
 3) "kUniqueAttributeKey" for properties that must be unique
 
 4) "kJoinTableMappingAttributeKey" to specify an array property that should be mapped to another DBTableRepresentation class
    For example, let's say you have an array named "people" in your "Department" class, represented by a "Person" class.
    You would add an attribute entry to the Department class with the array property name as a key, and a composite value consisting of
    the kJoinTableMappingAttributeKey constant with the name of the Person class, separated by a colon (":") 
    -- @"people" : [kJoinTable stringByAppendingString:@":DBPerson"]

 Implement this method by returning a dictionary with column names for keys and either strings or arrays of strings for column attributes as values
 
 Do not include attributes for the required properties handled in this superclass: (id, creationDate, modificationDate) in the dictionary
 
 @returns Return an NSDictionary of keys that correlate to column (property) names and values that correlate to attributes that should be applied to that column
 */
+ (NSDictionary *)tableAttributes;


/*! This class method allows you to set replacement table column names for the '<property>_id' names that
    DBBuilder automatically applies to DBTableRepresentation class properties. Override it in your
    DBTableRepresentation subclasses where you want to provide different names for properties that are of a
    DBTableRepresentation subclass type. This allows you to map objects to ID numbers being stored in an existing
	database table you're using DBBuilder with.
 
 @return    Return an NSDictionary populated with the name of each property you want to change as the key,
            and the name you want to use for its table column as the value. Be sure to match capitalization 
			of the existing table column name.
*/
+ (NSDictionary *)overriddenColumnNames;

/*!
 A method to obtain the database table name for any subclassed instance
 
 @returns The name of the SQLite table for any subclass
 */
- (NSString *)tableName;

/*! 
 A convenience method to set a subclassed instance's 'dirty' flag
 */
- (void)makeDirty;

/*!
 A convenience method to clear a subclassed instance's 'dirty' flag
 */
- (void)makeClean;

/*!
 A convenience method to create a join-array definition when overriding the -tableAttributes method
 */
- (NSArray *)arrayAttributeDefinitionForClass:(NSString *)className shouldCascadeDelete:(BOOL)shouldCascadeDelete;

/*!
 Access to the various meta data dictionaries that describe properties, attributes, database table columns, etc.
*/
- (NSDictionary *)propertiesCache;

// methods used by DBBuilder internals
- (BOOL)verifyTableWithRetry:(BOOL)retry;
- (void)buildTableDict;
- (BOOL)isDBTableRepresentationClass;

NS_ASSUME_NONNULL_END

@end
