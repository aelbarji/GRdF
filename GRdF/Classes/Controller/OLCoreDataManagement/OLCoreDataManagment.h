//
//  DataManagment.h
//  OnatysLibrary
//
//  Created by Damien Latournerie on 21/01/12.
//  Copyright (c) 2012 ONATYS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OLCoreDataManagment : NSObject {
    
    NSMutableArray          *results;
    
}

/**
 * Perform commit to save changes
 *
 * @param _managedObjectContext Managed object context
 *
 * @return (TRUE/FALSE)
 *
 */
- (BOOL) performCommit              : (NSManagedObjectContext *)    _managedObjectContext;

/**
 * Delete all entries from one table
 *
 * @param _managedObjectContext Managed object context
 * @param _entityDescription Table name
 *
 * @return (TRUE/FALSE)
 *
 */
- (BOOL) deleteAllObjects           : (NSManagedObjectContext *)    _managedObjectContext
                                    : (NSString *)                  _entityDescription;
/**
 * Delete one entry from one table
 *
 * @param _managedObjectContext Managed object context
 * @param _entityDescription Table name
 * @param _predicate Predicate request
 *
 * @return (TRUE/FALSE)
 *
 */
- (void) deleteObject               : (NSString *)                  _entityDescription
                                    : (NSManagedObjectContext *)    _managedObjectContext
                                    : (NSString *)                  _predicate;

/**
 * List entries from table, with selection or order (options)
 *
 * @param _managedObjectContext Managed object context
 * @param _sortDescriptorList List of label to order by (firstName|lastName)
 * @param _sortDescriptorOrderList List of order by value (ASC|DESC)
 * @param _tagPredicate Request to select one or severals values (description contains[cd] 'bon')
 * @param _entityDescription Table name
 * @param _predicate Predicate request
 *
 * @return (TRUE/FALSE)
 *
 */
- (NSArray *) listResult            : (NSManagedObjectContext *)    _managedObjectContext
                                    : (NSString *)                  _sortDescriptorList
                                    : (NSString *)                  _sortDescriptorOrderList
                                    : (NSString *)                  _tagPredicate
                                    : (NSString *)                  _databaseName;

- (NSArray *) listResultPred        : (NSManagedObjectContext *)    imanagedObjectContext
                                    : (NSString *)                  isortDescriptorList
                                    : (NSString *)                  isortDescriptorOrderList
                                    : (NSPredicate *)               itagPredicate
                                    : (NSString *)                  idatabaseName;

- (BOOL) loadCsvData                : (NSManagedObjectContext *)    _managedObjectContext
                                    : (NSManagedObjectModel *)      _managedObjectModel
                                    : (NSString *)                  _tableName 
                                    : (NSString *)                  _filName;

- (BOOL) addCsvData                 : (NSManagedObjectContext *)    _managedObjectContext
                                    : (NSManagedObjectModel *)      _managedObjectModel
                                    : (NSString *)                  _tableName
                                    : (NSMutableDictionary *)       _csvLineDict;

- (void) freeMemory;

@end
