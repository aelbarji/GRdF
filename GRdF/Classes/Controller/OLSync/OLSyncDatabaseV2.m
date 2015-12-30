//
//  OLSyncDatabase.m
//  Synchro_bdd
//
//  Created by yangdong on 12-9-17.
//  Copyright (c) 2012年 yangdong. All rights reserved.
//

#define kDataThreshold          200

#import "OLSyncDatabaseV2.h"

@interface OLSyncDatabaseV2()
{
    NSString                *_entityName;             // entity (table) name

//    NSXMLParser             *_xmlParser;
    NSString                *_currentElementName;     // store current xml node element
    NSMutableString         *_currentElementValue;    // store current xml node value
    NSMutableDictionary     *_lineDict;               // attribute/value pairs found in xml
    NSMutableDictionary     *_lineDictRef;            // attribute/@"" pairs related to entity
    NSMutableArray          *_xmlDataRows;            // array of lineDict = rows to insert
    
    NSString                *_returnValue;
    
    
    NSPersistentStoreCoordinator *_persistentStore;
}
@end

@implementation OLSyncDatabaseV2
@synthesize delegate=_delegate;

#pragma mark - public instance methods



- (NSString *)OLSyncBDDEntity: (NSString *)  entityName
               withAttributes: (NSArray *)   entityAttributes
              usingDateFormat: (NSString *)  format
        usingDecimalSeparator: (NSString *)  separator
          withXmlStreamString: (NSURL *)     xmlStreamURL
{

    DLog(@"OLSyncBDDEntity.start : entityName : %@", entityName);
    
    NSManagedObjectContext *moc     = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType] ;
    [moc setPersistentStoreCoordinator:_persistentStore];
    
    NSUndoManager *anUndoManager    = [[NSUndoManager alloc] init];
    [anUndoManager setLevelsOfUndo:3];
    
    [moc setUndoManager:anUndoManager];
    [anUndoManager release];
    
    // retain entity name (table name)
    if (_entityName)
    {
        [_entityName release];
        _entityName=nil;
    }
    _entityName=[[NSString stringWithString:entityName] retain];

    // clean previous instance of variables if needed
    if (_xmlDataRows)
        MF_COCOA_RELEASE(_xmlDataRows);
//    if (_xmlParser)
//        MF_COCOA_RELEASE(_xmlParser);

    // create and retain empty dictionary of attributes (columns) to fill with xml data
    if (_lineDictRef)
    {
        MF_COCOA_RELEASE(_lineDictRef);
    }
    
    _lineDictRef=[[NSMutableDictionary alloc] init];

    for(NSString * attribute in entityAttributes)
        [_lineDictRef setValue:@"" forKey:attribute];
    
    DLog(@"OLSyncBDDEntity.xml parsing");
    
    // --------------------------
    // Phase 1 : XML Parsing
    // --------------------------
    _xmlDataRows = [[NSMutableArray alloc] init];
    // 2014/06/17 JPh : to solve leak issue while using initWithContentsOfURL methods
    // _xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:xmlStreamURL];
    NSData * dataXml        = [NSData dataWithContentsOfURL:xmlStreamURL];
    NSXMLParser *xmlParser = [[NSXMLParser alloc]initWithData:dataXml];

    xmlParser.delegate     = self;
    [xmlParser parse];

    xmlParser.delegate     = nil;
    [xmlParser release];
    dataXml                 = nil;
    
    if (_returnValue != nil)
    {
        [self tellDelegateSynchronisationEndWithMessage:_returnValue];
        
        [moc setUndoManager:nil];
        MF_COCOA_RELEASE(moc);
        MF_COCOA_RELEASE(_xmlDataRows);
        MF_COCOA_RELEASE(_lineDictRef);
//        MF_COCOA_RELEASE(_xmlParser);
        
        return _returnValue;
    }
    
    // DLog(@"dictRef: %@", _lineDictRef);
    // DLog(@"xmlDataRows: %@", _xmlDataRows);
    
    DLog(@"OLSyncBDDEntity.clean entity");
                           
    // --------------------------
    // Phase 2 : clean syncEntity
    // --------------------------
    NSString *syncEntityName = [NSString stringWithFormat:@"%@%@",
                                kSyncEntityPrefix,
                                entityName];
    
    [self           clearEntity:syncEntityName
       withManagedObjectContext:moc];
    
    DLog(@"OLSyncBDDEntity.insert row");
    
    // --------------------------
    // Phase 3 : insert new data into syncEntity
    // --------------------------
    
    // DLog(@"_xmlDataRows:%@", _xmlDataRows);
    
    [self       addDataFull: _xmlDataRows
                   inEntity: syncEntityName
            usingDateFormat: (format ? format :kDefaultSyncDateFormat)
      usingDecimalSeparator: (separator ? separator :kDefaultDecimalSeparator)
    withManagedObjetContext: moc];

    DLog(@"OLSyncBDDEntity.move data");
                           
    // --------------------------
    // Phase 4 : move syncEntity data into entity
    // --------------------------
    [self   copyRecordsFrom:syncEntityName
                         to:entityName
   withManagedObjectContext:moc];

    [self tellDelegateSynchronisationEndWithMessage:_returnValue];
    
    [moc setUndoManager:nil];
    MF_COCOA_RELEASE(moc);
    MF_COCOA_RELEASE(_xmlDataRows);
    MF_COCOA_RELEASE(_lineDictRef);
//    MF_COCOA_RELEASE(_xmlParser);
    
    DLog(@"OLSyncBDDEntity.end");
    
    return _returnValue;
}

-(void) tellDelegateSynchronisationEndWithMessage:(NSString *) msg
{
    if (_delegate != nil)
        if ([_delegate respondsToSelector:@selector(databaseSynchronizationDidEnd:withStatus:andMessage:)])
            [_delegate databaseSynchronizationDidEnd:self
                                          withStatus:(msg==nil)
                                          andMessage:msg];
}


#pragma mark - private instance methods
#pragma mark - core data management
- (id)          addData: (NSDictionary *)           lineDict
               inEntity: (NSString *)               entityName
        usingDateFormat: (NSString *)               format
  usingDecimalSeparator: (NSString *)               separator
withManagedObjetContext: (NSManagedObjectContext *) moc
{
    NSNumberFormatter * numFormatter = [[NSNumberFormatter alloc] init];
    // [numFormatter setLocale:[NSLocale currentLocale]];
    [numFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numFormatter setDecimalSeparator:separator];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [dateFormat setDateFormat:format ];
     
    id newRecord = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:moc];
    
    for (id key in lineDict)
    {
        // build setter = "set" & Key (turn 1st char to uppercase)
        NSMutableString *msSetterName=[[NSMutableString alloc] initWithFormat:@"set%@:", key];
        [msSetterName replaceOccurrencesOfString:@"\""
                                      withString:@""
                                         options:NSCaseInsensitiveSearch
                                           range:NSMakeRange(0, [msSetterName length])];
       
        // build getter = key (turn 1st char to lowercase)
        NSMutableString *  msGetterName=[[NSMutableString alloc] initWithFormat:@"%@", key];
        [msGetterName replaceOccurrencesOfString:@"\""
                                      withString:@""
                                         options:NSCaseInsensitiveSearch
                                           range:NSMakeRange(0, [msGetterName length])];
        
         // retreive attribute className using getter
        NSString *attributeValueClassName= [[[[[moc.persistentStoreCoordinator.managedObjectModel entitiesByName] objectForKey:entityName] attributesByName] objectForKey:[msGetterName stringByReplacingCharactersInRange:NSMakeRange(0,1)                                                             withString:[[msGetterName  substringToIndex:1] lowercaseString]]] attributeValueClassName];
        
        
        if ([attributeValueClassName isEqualToString:@"NSNumber"])
        {
            //   @"[^0-9,]" [NSString stringWithFormat:@"[^0-9%@]",separator]
            NSRegularExpression *regex=[NSRegularExpression
                                        regularExpressionWithPattern:[NSString stringWithFormat:@"[^0-9%@]",separator]
                                        options:NSRegularExpressionCaseInsensitive
                                        error:nil];

            [newRecord performSelector:NSSelectorFromString([msSetterName stringByReplacingCharactersInRange:NSMakeRange(3,1)                                                             withString:[[msSetterName substringWithRange:NSMakeRange(3,1)] uppercaseString]]) withObject:[numFormatter numberFromString:[regex stringByReplacingMatchesInString:[lineDict objectForKey:key] options:0 range:NSMakeRange(0, [[lineDict objectForKey:key ]  length]) withTemplate:@""]] ];

        }
        else if ([attributeValueClassName isEqualToString:@"NSDate"])
        {
            NSMutableString *msDateStringValue=[[NSMutableString alloc] initWithFormat:@"%@", [lineDict objectForKey:key]];
            [msDateStringValue replaceOccurrencesOfString:@"\n" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msDateStringValue length])];
            [newRecord performSelector:NSSelectorFromString([msSetterName stringByReplacingCharactersInRange:NSMakeRange(3,1)                                                             withString:[[msSetterName substringWithRange:NSMakeRange(3,1)] uppercaseString]]) withObject:[dateFormat dateFromString:msDateStringValue] ];
            [msDateStringValue release];
        }
        else if ([attributeValueClassName isEqualToString:@"NSString"])
        {
            /*  2013-06-12 : test purpose
            NSMutableString *msStringValue=[[NSMutableString alloc] initWithFormat:@"%@", [lineDict objectForKey:key]];

             DLog(@"line dict value: %@", [lineDict objectForKey:key]);
             DLog(@"cstringUsingUTF8: %s",[[lineDict objectForKey:key] cStringUsingEncoding:NSUTF8StringEncoding]);
             DLog(@"stringWithUTF8String: %@",[NSString stringWithUTF8String:[[lineDict objectForKey:key] cStringUsingEncoding:NSUTF8StringEncoding]]);
             DLog(@"stringWithCString: %@", [NSString stringWithCString:[[lineDict objectForKey:key] cStringUsingEncoding:NSISOLatin1StringEncoding] encoding:NSUTF8StringEncoding]);
             DLog(@"stringwithUtf8string: %@",[NSString stringWithUTF8String:[lineDict objectForKey:key]]);
             
             NSData *data=[[lineDict objectForKey:key] dataUsingEncoding:NSUTF8StringEncoding];
             NSString *xml=[[NSString alloc] initWithBytes:[data bytes]
             length:[data length]
             encoding:NSUTF8StringEncoding];
             DLog(@"data : %@", xml );
             [xml release];

             
             // ----possible alternative---- (doesn't work for "double" utf8 sequences such as \\u00C3\\u00A9)
             //            NSMutableString *msStringValue2=[[NSMutableString alloc] initWithCString:[[lineDict objectForKey:key] cStringUsingEncoding:NSUTF8StringEncoding] encoding:NSNonLossyASCIIStringEncoding] ;
             // ----------------------------
             */

            NSMutableString *msStringValue=[[NSMutableString alloc] initWithUTF8String:[[lineDict objectForKey:key] cStringUsingEncoding:NSUTF8StringEncoding]];
            
            
            [msStringValue replaceOccurrencesOfString:@"\\u0027" withString:@"'" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\0022" withString:@"\"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\u00C3\\u00A9" withString:@"é" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\u00C3\\u00A8" withString:@"è" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\u0026" withString:@"&" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\u3E" withString:@">" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\u3C" withString:@"<" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\u00C3\\u00A0" withString:@"à" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\u00C3\\u00AA" withString:@"ê" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\u00C3\\u00AB" withString:@"ë" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\u00C3\\u00A7" withString:@"ç" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\u00C3\\u00B4" withString:@"ô" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\u00C3\\u0089" withString:@"ù" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\u00C3\\u00AF" withString:@"ï" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\n    " withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\n  " withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            
            
            [msStringValue replaceOccurrencesOfString:@"\"" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            //[msStringValue replaceOccurrencesOfString:@"\n" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            
//            NSArray *tmpArray = [ msStringValue componentsSeparatedByString:@"\n" ];
            
            [msStringValue replaceOccurrencesOfString:@"\n\n" withString:@"\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            
            
            NSString *tmpString = [msStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//          2013-08-14 : JPhB -> to allow
//            NSArray *tmpArray = [ tmpString componentsSeparatedByString:@"\n" ];
//            if ([ tmpArray count ] > 1 )
//                tmpString = [ tmpArray objectAtIndex:0 ];
             
            
            [newRecord performSelector:NSSelectorFromString([msSetterName stringByReplacingCharactersInRange:NSMakeRange(3,1)                                                             withString:[[msSetterName substringWithRange:NSMakeRange(3,1)] uppercaseString]]) withObject:[tmpString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
            [msStringValue release];  
        }
        else // add object
        {
            [newRecord performSelector:NSSelectorFromString([msSetterName stringByReplacingCharactersInRange:NSMakeRange(3,1)                                                             withString:[[msSetterName substringWithRange:NSMakeRange(3,1)] uppercaseString]]) withObject:[lineDict objectForKey:key]];
        }
        
        
        [msSetterName release];
        [msGetterName release];
    }
    

    [numFormatter release];
    [dateFormat release];
    
	NSError *error;
    if ([newRecord validateForUpdate:&error])  // assess record internal validation
    {
        error = nil;
        if (![moc save:&error])
        {
            if (_returnValue)
                MF_COCOA_RELEASE(_returnValue);

            _returnValue = [[NSString stringWithFormat:@"domain:sync bdd, error code:%i - %@",
                            [error code],
                            error.description] retain];
            [moc rollback];
            return nil;
        }
        else
            return newRecord;
    }
    else
    {
        if (_returnValue)
            MF_COCOA_RELEASE(_returnValue);

        _returnValue = [[NSString stringWithFormat:@"domain:sync bdd, error code:%i - %@",
                        [error code],
                        error.description] retain];
        return nil;
    }
}

- (id)          addDataFull: (NSArray *)                lineDicts
                   inEntity: (NSString *)               entityName
            usingDateFormat: (NSString *)               format
      usingDecimalSeparator: (NSString *)               separator
    withManagedObjetContext: (NSManagedObjectContext *) moc
{
    NSNumberFormatter * numFormatter = [[NSNumberFormatter alloc] init];
    [numFormatter   setNumberStyle   : NSNumberFormatterDecimalStyle];
    [numFormatter setDecimalSeparator: separator];
    
    NSDateFormatter *dateFormat      = [[NSDateFormatter alloc] init];
    [dateFormat     setTimeZone      : [NSTimeZone timeZoneWithName:@"GMT"]];
    [dateFormat     setDateFormat    : format ];
 
    NSInteger   count = 0;
    
    for (NSMutableDictionary *lineDict in lineDicts)
    {
    
    id newRecord = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:moc];
    
    for (id key in lineDict)
    {
        // build setter = "set" & Key (turn 1st char to uppercase)
        NSMutableString *msSetterName=[[NSMutableString alloc] initWithFormat:@"set%@:", key];
        [msSetterName replaceOccurrencesOfString:@"\""
                                      withString:@""
                                         options:NSCaseInsensitiveSearch
                                           range:NSMakeRange(0, [msSetterName length])];
        
        // build getter = key (turn 1st char to lowercase)
        NSMutableString *  msGetterName=[[NSMutableString alloc] initWithFormat:@"%@", key];
        [msGetterName replaceOccurrencesOfString:@"\""
                                      withString:@""
                                         options:NSCaseInsensitiveSearch
                                           range:NSMakeRange(0, [msGetterName length])];
        
        // retreive attribute className using getter
        NSString *attributeValueClassName= [[[[[moc.persistentStoreCoordinator.managedObjectModel entitiesByName]
                                               objectForKey:entityName] attributesByName]
                                             objectForKey:[msGetterName stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                                                                withString:[[msGetterName  substringToIndex:1]
                                                                                                            lowercaseString]]]
                                            attributeValueClassName];
        
        
        if ([attributeValueClassName isEqualToString:@"NSNumber"])
        {
            //   @"[^0-9,]" [NSString stringWithFormat:@"[^0-9%@]",separator]
            NSRegularExpression *regex= [NSRegularExpression
                                         regularExpressionWithPattern:[NSString stringWithFormat:@"[^0-9%@]",separator]
                                         options:NSRegularExpressionCaseInsensitive
                                         error:nil];
            
            [newRecord performSelector: NSSelectorFromString([msSetterName
                                                             stringByReplacingCharactersInRange:NSMakeRange(3,1)
                                                             withString:[[msSetterName substringWithRange:NSMakeRange(3,1)]
                                                                         uppercaseString]])
                            withObject: [numFormatter numberFromString:[regex stringByReplacingMatchesInString:[lineDict objectForKey:key]
                                                                                                      options:0
                                                                                                        range:NSMakeRange(0, [[lineDict objectForKey:key ]  length])
                                                                                                 withTemplate:@""]] ];
            
            regex                       = nil;
        }
        else if ([attributeValueClassName isEqualToString:@"NSDate"])
        {
            NSMutableString *msDateStringValue = [[NSMutableString alloc]
                                                  initWithFormat:@"%@", [lineDict objectForKey:key]];
            [msDateStringValue replaceOccurrencesOfString:@"\n" withString:@""
                                                  options:NSCaseInsensitiveSearch
                                                    range:NSMakeRange(0, [msDateStringValue length])];
            
            [newRecord performSelector:NSSelectorFromString([msSetterName
                                                             stringByReplacingCharactersInRange:NSMakeRange(3,1)
                                                             withString:[[msSetterName substringWithRange:NSMakeRange(3,1)]
                                                                         uppercaseString]])
                            withObject:[dateFormat dateFromString:msDateStringValue] ];
            
            MF_COCOA_RELEASE(msDateStringValue);
        }
        else if ([attributeValueClassName isEqualToString:@"NSString"])
        {
            /*  2013-06-12 : test purpose
             NSMutableString *msStringValue=[[NSMutableString alloc] initWithFormat:@"%@", [lineDict objectForKey:key]];
             
             DLog(@"line dict value: %@", [lineDict objectForKey:key]);
             DLog(@"cstringUsingUTF8: %s",[[lineDict objectForKey:key] cStringUsingEncoding:NSUTF8StringEncoding]);
             DLog(@"stringWithUTF8String: %@",[NSString stringWithUTF8String:[[lineDict objectForKey:key] cStringUsingEncoding:NSUTF8StringEncoding]]);
             DLog(@"stringWithCString: %@", [NSString stringWithCString:[[lineDict objectForKey:key] cStringUsingEncoding:NSISOLatin1StringEncoding] encoding:NSUTF8StringEncoding]);
             DLog(@"stringwithUtf8string: %@",[NSString stringWithUTF8String:[lineDict objectForKey:key]]);
             
             NSData *data=[[lineDict objectForKey:key] dataUsingEncoding:NSUTF8StringEncoding];
             NSString *xml=[[NSString alloc] initWithBytes:[data bytes]
             length:[data length]
             encoding:NSUTF8StringEncoding];
             DLog(@"data : %@", xml );
             [xml release];
             
             
             // ----possible alternative---- (doesn't work for "double" utf8 sequences such as \\u00C3\\u00A9)
             //            NSMutableString *msStringValue2=[[NSMutableString alloc] initWithCString:[[lineDict objectForKey:key] cStringUsingEncoding:NSUTF8StringEncoding] encoding:NSNonLossyASCIIStringEncoding] ;
             // ----------------------------
             */
            
            NSMutableString *msStringValue=[[NSMutableString alloc] initWithUTF8String:[[lineDict objectForKey:key] cStringUsingEncoding:NSUTF8StringEncoding]];
            
            
            [msStringValue replaceOccurrencesOfString:@"\\u0027" withString:@"'" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\0022" withString:@"\"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\u00C3\\u00A9" withString:@"é" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\u00C3\\u00A8" withString:@"è" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\u0026" withString:@"&" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\u3E" withString:@">" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\u3C" withString:@"<" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\u00C3\\u00A0" withString:@"à" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\u00C3\\u00AA" withString:@"ê" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\u00C3\\u00AB" withString:@"ë" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\u00C3\\u00A7" withString:@"ç" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\u00C3\\u00B4" withString:@"ô" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\u00C3\\u0089" withString:@"ù" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\\u00C3\\u00AF" withString:@"ï" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\n    " withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            [msStringValue replaceOccurrencesOfString:@"\n  " withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            
            
            [msStringValue replaceOccurrencesOfString:@"\"" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            //[msStringValue replaceOccurrencesOfString:@"\n" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            
            //            NSArray *tmpArray = [ msStringValue componentsSeparatedByString:@"\n" ];
            
            [msStringValue replaceOccurrencesOfString:@"\n\n" withString:@"\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [msStringValue length])];
            
            
            NSString *tmpString = [msStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            //          2013-08-14 : JPhB -> to allow
            //            NSArray *tmpArray = [ tmpString componentsSeparatedByString:@"\n" ];
            //            if ([ tmpArray count ] > 1 )
            //                tmpString = [ tmpArray objectAtIndex:0 ];
            
            
            [newRecord performSelector:NSSelectorFromString([msSetterName stringByReplacingCharactersInRange:NSMakeRange(3,1)                                                             withString:[[msSetterName substringWithRange:NSMakeRange(3,1)] uppercaseString]]) withObject:[tmpString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
            
            tmpString       = nil;
            MF_COCOA_RELEASE(msStringValue);
        }
        else // add object
        {
            [newRecord performSelector:NSSelectorFromString([msSetterName stringByReplacingCharactersInRange:NSMakeRange(3,1)                                                             withString:[[msSetterName substringWithRange:NSMakeRange(3,1)] uppercaseString]]) withObject:[lineDict objectForKey:key]];
        }
        
        attributeValueClassName = nil;
        MF_COCOA_RELEASE(msSetterName);
        MF_COCOA_RELEASE(msGetterName);
        

        
    }
    
        count++;
        if ( (count % kDataThreshold) == 0 )
        {
            NSError *saveError;
            if (![moc save:&saveError])
            {
                
                if (_returnValue)
                    MF_COCOA_RELEASE(_returnValue);

                _returnValue = [[NSString stringWithFormat:@"domain: sync bdd, error code: %i - %@",
                                 [saveError code],
                                 saveError.description] retain];
                [moc rollback];
            }
        }
    }
    
    MF_COCOA_RELEASE(numFormatter);
    MF_COCOA_RELEASE(dateFormat);
    
	NSError *error;
    if ( moc.hasChanges && ![moc save:&error])
    {
        if (_returnValue)
            MF_COCOA_RELEASE(_returnValue);

        _returnValue = [[NSString stringWithFormat:@"domain:sync bdd, error code:%i - %@",
                         [error code],
                         error.description] retain];
        [moc rollback];
        return nil;
    }
    else
        return nil;
    
}

// Transfert de toutes les données de la table intermédiaire vers la table finale
- (void)    copyRecordsFrom: (NSString *)               sourceEntity
                         to: (NSString *)               destinationEntity
   withManagedObjectContext: (NSManagedObjectContext *) moc
{
    // Suppression de toutes les données de la table finale
    [self       clearEntity:destinationEntity
   withManagedObjectContext:moc];
    
    // Insertion des données de la table intermédiaire dans la table finale
    NSArray *results        = [self fetchRecordsFromEntity:sourceEntity
                           withManagedObjectContext:moc];
    NSDictionary *attributes = [[NSEntityDescription entityForName:sourceEntity inManagedObjectContext:moc] attributesByName];

    NSInteger   count       = 0;
    for (NSManagedObject *record in results)
    {
        NSManagedObject *newRecord = [NSEntityDescription insertNewObjectForEntityForName:destinationEntity inManagedObjectContext:moc];
        
        for (NSString *attr in attributes)
        {
            [newRecord setValue:[record valueForKey:attr] forKey:attr];
        }
        
        count++;
        if ( (count % kDataThreshold) == 0 )
        {
            NSError *saveError;
            if (![moc save:&saveError])
            {
                if (_returnValue)
                    MF_COCOA_RELEASE(_returnValue);

                _returnValue = [[NSString stringWithFormat:@"domain: final bdd, error code: %i - %@",
                                 [saveError code],
                                 saveError.description] retain];
                [moc rollback];
            }
        }
            
        
    }
    
    // Si une erreur s'est produite lors du transfert des données de la table intermédiaire vers la table finale
    NSError *saveError;
    if (moc.hasChanges && ![moc save:&saveError])
    {
        if (_returnValue)
            MF_COCOA_RELEASE(_returnValue);

        _returnValue = [[NSString stringWithFormat:@"domain: final bdd, error code: %i - %@",
                        [saveError code],
                        saveError.description] retain];
        [moc rollback];
        return;
    }

    // Suppression de toutes les données de la table intermédiaire
    [self           clearEntity:sourceEntity
       withManagedObjectContext:moc];
}

// Suppression de toutes les données de la table spécifiée
- (void)        clearEntity: (NSString *)               entityName
   withManagedObjectContext: (NSManagedObjectContext *) moc
{
    NSInteger count             = 0;
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                              inManagedObjectContext:moc];
    NSFetchRequest *request     = [[NSFetchRequest alloc] init];
    [request        setEntity   : entity];
    
    NSError *error              = nil;
    NSMutableArray *results     = [[moc executeFetchRequest:request error:&error] mutableCopy];
    for (id object in results)
    {
        [moc deleteObject:object];
        
        count++;
        if ( (count % kDataThreshold) == 0 )
        {
            error               = nil;
            if (![moc save:&error])
            {
                if (_returnValue)
                    MF_COCOA_RELEASE(_returnValue);
                _returnValue    = [[NSString stringWithFormat:@"domain:clear entity:%@, error code:%i - %@",
                                    entityName,
                                    [error code],
                                    error.description] retain];
                [moc rollback];
            }
        }

    }
    
    error = nil;
    
	if (moc.hasChanges && ![moc save:&error])
    {
        if (_returnValue)
            MF_COCOA_RELEASE(_returnValue);
        _returnValue            = [[NSString stringWithFormat:@"domain:clear entity:%@, error code:%i - %@",
                                    entityName,
                                    [error code],
                                    [error description]] retain];
        [moc rollback];

    }
    
    [results release];
    [request release];
}


// Récupération de toutes les données de la table spécifiée
- (NSArray *) fetchRecordsFromEntity: (NSString *)               entityName
            withManagedObjectContext: (NSManagedObjectContext *) moc
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:moc];
    NSFetchRequest *request     = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    NSError **error = nil;
    NSMutableArray *results     = [[moc executeFetchRequest:request error:error] mutableCopy];
    
    [request release];
    return [results autorelease];
}



#pragma mark - NS_xmlParserDelegate methods
- (void)parserDidStartDocument:(NSXMLParser *)parser
{
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
     _currentElementName = [elementName copy];
    if(_currentElementValue)
    {
        [_currentElementValue release];
        _currentElementValue = nil;
    }
    
    if ([elementName isEqualToString:_entityName])
    {
       _lineDict = [[NSMutableDictionary dictionaryWithDictionary:_lineDictRef] retain];
    }
    

}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    // if end of entity: store line dict in _xmlDataRows
    if ([elementName isEqualToString:_entityName])
    {
        [_xmlDataRows addObject:_lineDict];
        
        [_lineDict release];
        _lineDict=nil;
    }
    else // for other element consider only referenced attributes
    {
        if ([_lineDict objectForKey:elementName]!=nil)
            [_lineDict setValue:_currentElementValue forKey:elementName];
    }
    
    [_currentElementName release];
    _currentElementName = nil;
    

}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if(!_currentElementValue)
        _currentElementValue = [[NSMutableString stringWithString:string] retain];
    else
        [_currentElementValue appendString:string];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    
    DLog(@"current Element (so far): %@", _currentElementName);
    DLog(@"linedict (so far): %@", _lineDict);
    DLog(@"values (so far): %@", _xmlDataRows);
    if (_returnValue)
        MF_COCOA_RELEASE(_returnValue);

    _returnValue = [[NSString stringWithFormat:@"domain: xml, error code:%i - %@",
                   [parseError code],
                   parseError.description] retain];
}



#pragma mark - initialization
- (id) initWithStore:(NSPersistentStoreCoordinator *)coordinator
{
    self = [super init];
    if (self) {
        if (coordinator != nil) {
            _persistentStore = coordinator;
            _lineDict = [[NSMutableDictionary dictionary] retain];
        }
    }
    return self;
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        _persistentStore = context.persistentStoreCoordinator;
        _lineDict = [[NSMutableDictionary dictionary] retain];
    }
    return self;
}


- (void)dealloc
{

    if (_lineDict)
        MF_COCOA_RELEASE(_lineDict);
    if (_lineDictRef)
        MF_COCOA_RELEASE(_lineDictRef);
    if (_currentElementName)
        MF_COCOA_RELEASE(_currentElementName);
    if (_currentElementValue)
        MF_COCOA_RELEASE(_currentElementValue);
    if (_returnValue)
        MF_COCOA_RELEASE(_returnValue);
    if (_entityName)
        MF_COCOA_RELEASE(_entityName);

//    if (_xmlParser)
//        MF_COCOA_RELEASE(_xmlParser);
    if (_xmlDataRows)
        MF_COCOA_RELEASE(_xmlDataRows);

    [super dealloc];
}

@end
