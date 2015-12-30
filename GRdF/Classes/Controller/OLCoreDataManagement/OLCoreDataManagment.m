    //
//  DataManagment.m
//  OnatysLibrary
//
//  Created by Damien Latournerie on 21/01/12.
//  Copyright (c) 2012 ONATYS. All rights reserved.
//

#import "OLCoreDataManagment.h"

@implementation OLCoreDataManagment {
    
}

// Perform commit
- (BOOL) performCommit              : (NSManagedObjectContext *)    _managedObjectContext
{
    
    DLog(@" -> begin");
    
    NSError *error;
    if ( ! [ _managedObjectContext save:&error])
    {
        return FALSE;
    }
    
    DLog(@" -> end");
    
    return TRUE;
}

// Delete all values
- (BOOL) deleteAllObjects           : (NSManagedObjectContext *)    _managedObjectContext
                                    : (NSString *)                  _entityDescription  
{

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:_entityDescription inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    NSError *error;
    NSArray *items = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    for (NSManagedObject *managedObject in items) {
        [_managedObjectContext deleteObject:managedObject];
    }
    if (![_managedObjectContext save:&error])
    {
        return FALSE;
    }
    
    return TRUE;
}

// List results
- (NSArray *) listResult     : (NSManagedObjectContext *)    imanagedObjectContext
                                    : (NSString *)                  isortDescriptorList
                                    : (NSString *)                  isortDescriptorOrderList
                                    : (NSString *)                  itagPredicate
                                    : (NSString *)                  idatabaseName
{

    
    // Init array
    if (results)
    {
        [ results removeAllObjects ];
        [ results release ];
        results = nil;
    }
        
    // results    = [ [ [ NSMutableArray alloc ] init ] retain ];
    // results    = [ [ NSMutableArray array ] retain ];
    
    // Define our table/entity to use  
    NSEntityDescription *entity     = [NSEntityDescription entityForName : idatabaseName inManagedObjectContext:imanagedObjectContext];
    NSFetchRequest      *request    = [[NSFetchRequest alloc] init];  
    [request setEntity:entity];   

    // Set tag predicate
    if ( [ itagPredicate length ] > 0 )
    {
        NSPredicate *tagPredicate = [ NSPredicate predicateWithFormat:itagPredicate ];
        [request setPredicate:tagPredicate];
    }
    
    // Set sort descriptors
    if ( [ isortDescriptorList length ] > 0 )
    {
        NSArray *sortDescriptorsArray       = [ isortDescriptorList         componentsSeparatedByString:@"|" ];
        NSArray *sortDescriptorsOrderArray  = [ isortDescriptorOrderList    componentsSeparatedByString:@"|" ];
        
        if ( [ sortDescriptorsArray count ] == [ sortDescriptorsOrderArray count ] )
        {
            NSMutableArray      *sortDescriptors = [[NSMutableArray alloc ] init];
            
            int nbDescriptors = [ sortDescriptorsArray count ];
            
            for (int i=0; i<nbDescriptors; i++)
            {
                // Define ascending / descending
                BOOL ascending = TRUE;
                if ( [ [ sortDescriptorsOrderArray objectAtIndex:i ] isEqualToString : @"DESC" ] ) 
                    ascending = FALSE;
                
                // Add descriptor
                NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:[ sortDescriptorsArray objectAtIndex:i ]  ascending:ascending]; 
                [ sortDescriptors addObject:descriptor ];
                [ descriptor release ];
                descriptor = nil;
            }
            
            // Add descriptors
            [ request setSortDescriptors:sortDescriptors ];
            [ sortDescriptors release ];
            sortDescriptors = nil;
        }
        else 
        {
            // Free memory
            [ request               release ]; 
            request = nil;
            
            return nil;
        }
    }
    
    // Execute request
    NSError *error = nil;
    
    // NSArray *res = [ _managedObjectContext executeFetchRequest:request error:&error ];
    NSArray *res = [[[NSArray alloc] initWithArray:[imanagedObjectContext executeFetchRequest:request error:&error]] autorelease];
    
    // Free memory
    [ request               release ];
    request = nil;
    
    // Check errors
    if (error) 
    {
        return nil;
    }
    
    // return results;
    return res;
}

// List results
- (NSArray *) listResultPred : (NSManagedObjectContext *)    imanagedObjectContext
                                    : (NSString *)                  isortDescriptorList
                                    : (NSString *)                  isortDescriptorOrderList
                                    : (NSPredicate *)               itagPredicate
                                    : (NSString *)                  idatabaseName
{

    // Init array
    if (results)
    {
        [ results removeAllObjects ];
        [ results release ];
        results = nil;
    }

    // results    = [ [ [ NSMutableArray alloc ] init ] retain ];
    // results    = [ [ NSMutableArray array ] retain ];
    
    // Define our table/entity to use  
    NSEntityDescription *entity     = [NSEntityDescription entityForName : idatabaseName inManagedObjectContext:imanagedObjectContext];
    NSFetchRequest      *request    = [[NSFetchRequest alloc] init];  
    [request setEntity:entity];   
    
    // Set tag predicate
    if ( itagPredicate != nil )
    {
        [request setPredicate:itagPredicate];
    }
    
    // Set sort descriptors
    if ( [ isortDescriptorList length ] > 0 )
    {
        NSArray *sortDescriptorsArray       = [ isortDescriptorList         componentsSeparatedByString:@"|" ];
        NSArray *sortDescriptorsOrderArray  = [ isortDescriptorOrderList    componentsSeparatedByString:@"|" ];
        
        if ( [ sortDescriptorsArray count ] == [ sortDescriptorsOrderArray count ] )
        {
            NSMutableArray      *sortDescriptors = [[NSMutableArray alloc ] init];
            
            int nbDescriptors = [ sortDescriptorsArray count ];
            
            for (int i=0; i<nbDescriptors; i++)
            {
                // Define ascending / descending
                BOOL ascending = TRUE;
                
                if ( [ [ sortDescriptorsOrderArray objectAtIndex:i ] isEqualToString : @"DESC" ] ) 
                    ascending = FALSE;
                
                // Add descriptor
                NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:[ sortDescriptorsArray objectAtIndex:i ]  ascending:ascending]; 
                [ sortDescriptors addObject:descriptor ];
                [ descriptor release ];
                descriptor = nil;
            }
            
            // Add descriptors
            [ request setSortDescriptors:sortDescriptors ];
            [ sortDescriptors release ];
            sortDescriptors = nil;
        }
        else 
        {
            // Free memory
            [ request               release ]; 
            request = nil;
            
            // Error
            NSLog(@"OLCoreDataManagment.listResult.Error1");
            return nil;
        }
    }
    
    // Execute request
    NSError *error = nil;
    
    // NSArray *res = [ _managedObjectContext executeFetchRequest:request error:&error ];
    NSArray *res = [[[NSArray alloc] initWithArray:[imanagedObjectContext executeFetchRequest:request error:&error]] autorelease];
    
    // Free memory
    [ request               release ];
    request = nil;
    
    // Check errors
    if (error) 
    {
        // Error
        NSLog(@"OLCoreDataManagment.listResult.error : %@", [ error description ] );
        return nil;
    }
    
    // return results;
    return res;
}

// Delete value
- (void) deleteObject           : (NSString *)                  _entityDescription  
                                : (NSManagedObjectContext *)    _managedObjectContext
                                : (NSString *)                  _predicate
{

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:_entityDescription inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    NSPredicate *tagPredicate = [NSPredicate predicateWithFormat:_predicate ];          
    [fetchRequest setPredicate:tagPredicate];
    NSError *error;
    NSArray *items = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    for (NSManagedObject *managedObject in items) {
        [_managedObjectContext deleteObject:managedObject];
    }
    if (![_managedObjectContext save:&error]) {
        NSLog(@"OLCoreDataManagment.deleteAllObjects.error'%@'", [ error description ]);
    }
    
}

// Load CSV files
- (BOOL) loadCsvData                : (NSManagedObjectContext *)    _managedObjectContext 
                                    : (NSManagedObjectModel *)      _managedObjectModel
                                    : (NSString *)                  _tableName 
                                    : (NSString *)                  _sourceFileName 
{
    BOOL        res    = TRUE;
    NSError     *error;
    NSString    *separator  = @",";
    NSArray     *csvLines   = [[NSArray alloc] initWithArray:
                         [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:_sourceFileName ofType:@"csv"]
                                                    encoding:NSUTF8StringEncoding error:&error] componentsSeparatedByString:@"\n"]];
    if (csvLines == nil)
    {
        NSLog(@"LoadCSV error: %@", error.description);
        // if needed, send notification to delegate => protocol to build
        // ...
        res = FALSE;
    } 
    else 
    {
        NSEnumerator    *theEnum        = [csvLines objectEnumerator];
        NSArray         *columnNames    = nil;
        int             columnsCount    = 0;
        NSString        *currentLine;
        
        NSMutableDictionary *csvLineDict = [NSMutableDictionary dictionary];
        
        while (nil != (currentLine = [theEnum nextObject]) )
        {
            if (![currentLine isEqualToString:@""] )        
            {
                
                // NSLog(@"currentLine:%@", currentLine);
                
                if (columnNames == nil) // Assuming first row contains column name
                {
                    columnNames = [currentLine componentsSeparatedByString:separator];
                    columnsCount = [columnNames count];
                    
                    // NSLog(@"columnNames:%@", columnNames);
                }
                else 
                {
                    NSArray *rowValues  = [currentLine componentsSeparatedByString:separator];
                    int valueCount = [rowValues count];
                    int index;
                    
                    for ( index = 0 ; index < columnsCount && index < valueCount ; index++ )
                    {
                        NSString *curValue = [rowValues objectAtIndex:index];
                        if (nil != curValue && ![curValue isEqualToString:@""])
                        {
                            // NSLog(@"curValue:%@", curValue);
                            [ csvLineDict setObject:curValue forKey:[columnNames objectAtIndex:index]];
                        }
                    }
                    if (![self addCsvData : _managedObjectContext : _managedObjectModel : _tableName : csvLineDict]) 
                    {
                        res = FALSE;
                        break;
                    }
                }
            }
        }
    }
    
    // Free memory
    [ csvLines release ];

    return res;
}

// Add CSV
- (BOOL) addCsvData : (NSManagedObjectContext *)    _managedObjectContext
                    : (NSManagedObjectModel *)      _managedObjectModel
                    : (NSString *)                  _tableName 
                    : (NSMutableDictionary *)       _csvLineDict

{    
    id newRecord = [NSEntityDescription insertNewObjectForEntityForName:_tableName inManagedObjectContext:_managedObjectContext];
    
    for (id key in _csvLineDict)
    {
        NSMutableString     *selectorName           = [[NSMutableString alloc] initWithFormat:@"set%@:", key];
        [selectorName replaceOccurrencesOfString:@"\"" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [selectorName length])];
        
        NSMutableString     *msGetterName           =[[NSMutableString alloc] initWithFormat:@"%@", key];
        [msGetterName replaceOccurrencesOfString:@"\"" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msGetterName length])];
        
        NSString            *getterName             = [msGetterName stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[msGetterName  substringToIndex:1] lowercaseString]];
        NSString            *attributeValueClassName= [[[[[_managedObjectModel entitiesByName] objectForKey:_tableName] attributesByName] objectForKey:getterName] attributeValueClassName];
        
        
        if ([attributeValueClassName isEqualToString:@"NSNumber"]) 
        {
            // NSLog(@"Number");
            NSNumber *data=[[NSNumber alloc] initWithDouble:[[_csvLineDict objectForKey:key] doubleValue]];
            [newRecord performSelector:NSSelectorFromString(selectorName) withObject:data];
            [ data release ];
            [ selectorName release ];
        }
        else if ([attributeValueClassName isEqualToString:@"NSDate"]) 
        {
            // NSLog(@"Date");  // assuming date formatted DD/MM/YYYY HH:MM:SS 
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"dd/mm/yyyy HH:mm:ss"];
            NSDate *data= [dateFormat dateFromString:[_csvLineDict objectForKey:key]];
            [newRecord performSelector:NSSelectorFromString(selectorName) withObject:data];
            [dateFormat release ];
            [ selectorName release ];
        }
        else  // consider remaining cases as string
        {
            // NSLog(@"Assuming String");
            NSMutableString *msStringValue=[[NSMutableString alloc] initWithFormat:@"%@", [_csvLineDict objectForKey:key]];
            [msStringValue replaceOccurrencesOfString:@"\"" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            
            [newRecord performSelector:NSSelectorFromString(selectorName) withObject:msStringValue];
            [ msStringValue release ];
            [ selectorName release ];
        }
        
        [ msGetterName release ];
        
    }
    
    // Commit changes
    [ self performCommit : _managedObjectContext ];
    
	NSError *error;
	if (![_managedObjectContext save:&error]) 
    {
        NSLog(@"OLCoreDataManagment.addCsvData.error:%@", error);
        return FALSE;
	}
    else 
        return TRUE;
    
}

- (void) freeMemory
{
    if (results)
    {
        [ results release ];
        results = nil;
    }
}

@end
