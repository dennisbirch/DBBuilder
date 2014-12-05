# DBBuilder
An add-on for FMDB, the excellent SQLite wrapper, to make working with SQLite databases in Cocoa applications even less painful.

DBBuilder's principle role is making the translation between the classes in your code and their representations as tables and columns in their underlying SQLite database.

DBBuilder builds the database tables from your class definitions, and maintains them (within limitations) as you make changes to those classes. It also has a handful of options to provide flexibility when working with existing database tables.

It creates queries and execution statements to perform CRUD operations on your database: add new instances, retrieve objects, update existing instances and delete instances.

It allows the developer to work more directly with instances of classes, rather than writing database code, but does allow accessing data directly with queries and execution statements where necessary.

## Requirements 
DBBuilder works with [Flying Meat's FMDB](http://github.com/ccgus/fmdb). You may want to download the latest version from the author's GitHub page.

Any projects you build with DBBuilder will of course require linking in the *libsqlite3.dylib* library.

DBBuilder uses ARC (Automatic Reference Counting), so you'll need to use a version of Xcode that supports it. The project was originally begun with Xcode 4.x, but has only been extensively tested in Xcode versions 5.1.1 and 6.x+.

## Usage
There are two main classes in DBBuilder:

1. **DBManager** - A class that represents a single SQLite database file.
2. **DBTableRepresentation** - A super-class for objects that need to be persisted to a database.

DBBuilder encourages using a default DBManager singleton instance to represent a project's primary data storage file. It also allows creating additional managers for secondary database files as necessary, but you would need to retain your own references to any you create. The DBManager does allow storing data to an in-memory store rather than to a file.

You create a subclass of DBTableRepresentation for each class whose instances you want to be persisted to disk or memory. There is no need to register these subclasses; they are detected at launch time by the manager. DBBuilder checks the database file's validity and creates any tables that are new, and updates existing tables as necessary to accommodate any changes made since the last time the application was run. (It does NOT drop tables or columns during this update process.)

###Configuring a DBManager
Whether you use the default DBManager or your own instances of this class, you need to provide it with minimal information before you can work with it. You provide this information by setting values for three properties:

* **dbFilePath** — If you want to persist your data to a file, you need to provide the path to that file with this DBManager property. If you want to use an in-memory database, set this property's value to nil.
* ***dbClassPrefix*** — Provide the prefix for your project's DBTableRepresentation instances. For example, the demo project's classes use the prefix "DBB", so the dbClassPrefix value is set to "DBB".
* **idColumnName** — Provide a name for the "id" column that is used in every table. DBBuilder will use this column for your DBTableRepresentation subclassess' itemID property. 

You can configure all three properties individually, or with a call to the DBManager class's `-configureWithFilePath:filePath:idColumnName:` method.

###Creating a database
You create a database with DBBuilder with an instance of DBManager. It is encouraged to use its `+defaultManager` convenience method to create a singleton instance. After configuring the manager as described above, you call the manager's `-database` method to obtain a reference to an _FMDatabase_ instance. After that minimal setup you can begin initializing instances of your DBTableRepresentation subclasses to perform CRUD operations.

###Data Types
DBBuilder supports storing string, numeric, boolean, and date properties. You can also store instances of other DBRepresentation subclass instances in your classes. And by setting an attribute, you can store arrays of any of the above property types.

###Subclassing DBTableRepresentation
As stated above, you work with DBBuilder by creating subclasses of the DBTableRepresentation class, which in turn writes to the SQL file or in-memory store to represent your class as a set of tables with appropriate columns. Each class gets its own table, and join tables are created to store the contents of arrays.

####Columns = Properties
It is required to create a property for each database column you want to store in the database. You can create properties that you do not wish to be persisted by setting an attribute in a class method provided for that purpose. You can set other attributes to influence database behavior.

####Setting Attributes
Each column that you want to create storage for must be represented in a subclass as a property. If you want to create a property in a DBTableRepresentation subclass that you do not want to be stored in the database, override the `+tableAttributes` method for that class and return a dictionary that includes the property name as the key and the _kDoNotPersist_ constant as the value. If you want to require a value in the database for a property, use the _kNotNull_ constant. If you want to require unique values for column entries, use the _kUnique_ constant as a value. You can combine attributes for a property by setting them as elements of an array you use for the value (e.g. `@{@"myProperty" : @[kNotNull, kUnique]}`).

####Array Properties
You can use an NSArray as a property in a DBTableRepresentation class if you include an attribute that defines the mapping required to create a join table. This uses the same table attribute syntax as described above, with a slight twist. The value needs to be the constant _kJoinTableMapping_, followed by a ":", followed by the name of the class *(not the column name)* that it maps to. For example, if you were including a "people" array property for your "DBPerson" class the syntax would be `@{@"people" : [kJoinTableMapping stringByAppendingString:@":DBPerson"]}`

###Initializing DBTableRepresentation subclasses
There are a few different initializers you can use to create instances of your DBTableRepresentation subclasses. They all require an instance of DBManager as the last parameter. Depending on your needs, you may want to use:

* `-initWithManager:` - you get back a bare instance which needs to have its property values defined,
* `-initWithID:manager` - you get back an instance that has been assigned the ID provided (only useful after the instance has been saved to the database), or 
* `-initWithDictionary:manager` - you get back an instance with its property values filled in by matching dictionary keys by name. 

There is also a convenience method for creating and saving an instance: `+savedInstanceWithValues:manager` - combines the functionality of -initWithDictionary:manager with a save operation, and returns the saved instance.

###Accessing sets of data
DBBuilder offers two convenience methods for accessing data in the form of arrays of DBTableRepresentation subclasses:

* `+objectsWithOptions:manager` - Takes a dictionary of options that let you define columns to include, conditional clauses, sort order, grouping order, and whether or not to return only distinct values. As with the single instance initializers, it also takes a DBManager instance.
* `+queueObjectsWithOptions:manager:completionBlock` - works the same as the objectsWithOptions:manager method, but uses an *FMDatabaseQueue* to perform its action on a background queue.

###Saving/Updating instances
Saving a DBTableRepresentation subclass instance is as simple as calling the `-saveToDB` method. It returns a boolean value indicating whether or not it was successful. Alternatively, you can use the `-queueSaveToDBWithCompletionBlock` method to use a FMDatabaseQueue instance for saving on a separate serial queue. These methods both save new instances and update existing instances you've changed.

####Tracking 'Dirty' status
The DBTableRepresentation class has an *isDirty* property that lets you track whether an instance has changes. It is automatically set to false on a successful save. If you want to avoid the overhead of updating instances that have not been changed (and updating their *modificationDate* property), you should set and check for the *isDirty* state. There are convenience methods for setting its state:

* `-makeDirty` - sets the isDirty state to true
* `-makeClean` - sets the isDirty state to false

###Deleting instances
Deleting instances of DBTableRepresentation subclasses is accomplished with the `+deleteObject:` class method. 

You can call the `+deleteObjects:` method to delete an array of DBTableRepresentation subclasses of the same type.

You need to call either of these methods on a DBTableRepresentation subclass of the type you want to delete. They both remove not only the table row for the item(s) you delete, but also join-table references to array properties they might contain, and references to other DBTableRepresentation subclass properties.

If you set the *kCascadingArrayDeletionAttributeKey* attribute on an array property, DBBuilder will also delete the database rows for the objects referred to in the array.

###Working with existing database tables
As mentioned above, DBBuilder builds and maintains database tables from the DBTableRepresentation subclasses in your Xcode project. However, it offers a couple of functions that give you some flexibility in working with existing tables.

* `+ (NSString *)overriddenTableName` - Lets you specify a name for a table other than the one DBBuilder would automatically create.
*  `+ (NSDictionary *)overriddenColumnNames` - Lets you specify names for table columns used for DBTableRepresentation subclass properties. You can use this method to adapt to existing table columns that store a foreign key ID to another object's table. DBBuilder automatically creates column names for such properties formatted as <property-name>_id. If that won't work with an existing database table you need to access, return an NSDictionary with the property name as key and the column name to use as the value. Be sure to match capitalization as case-sensitive comparisons are used.

##Demo Projects
The DBBuilder archive includes both iOS and Mac demo projects. They exercise a range of functionality. They demonstrate implementing a simple database application, and includes a number of unit tests that may help guide you in using DBBuilder in your own projects.

You can run the iOS demo project with the iOS 7 or later simulator. The Mac demo project has been set to use OS X as its deployment target, but may work with earlier versions of OS X.

##Using DBBBuilder in your own Projects
To use DBBuilder in your own Cocoa projects, you need to copy the source files within the "DBBuilder-Classes" folder into your project. You will also need to add FMDB to your project as mentioned above.

##Contacting the author
DBBuilder is a project the author has worked on off and on (mostly off) since 2012. While he has tested it to the extent possible, there very well may be undiscovered bugs or use cases he hasn't considered or deemed to address. You may use this code as-is, and implement your own changes to it. In any event, the author would appreciate any suggestions for improvements, and hearing from you if you find this useful. If you would like to contribute code, please send a pull request.

You can leave comments via the contact form at <http://www.pandaware.com/support.html>.

##License
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:


The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.


THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

