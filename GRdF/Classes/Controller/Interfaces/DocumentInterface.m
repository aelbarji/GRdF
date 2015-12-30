//
//  DocumentInterface.m
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 18/11/2014.
//  Copyright (c) 2014 Onatys. All rights reserved.
//

// -- NSManaged Entity
#import "GRDFDocument.h"


#import "DocumentInterface.h"

@implementation DocumentInterface


#pragma mark - document search management
+ (NSArray *) documentsWithinLatitudeSpan: (double)  aLatitudeSpan
                         andLongitudeSpan: (double)  aLongitudeSpan
                             fromLatitude: (double)  aLatitude
                             andLongitude: (double)  aLongitude
{
    DLog(@"-> begin");
    
    NSMutableArray *results = [NSMutableArray array];
    
    // build criterias according to searchable region
    double minLatitude      = aLatitude  - aLatitudeSpan;
    double maxLatitude      = aLatitude  + aLatitudeSpan;
    double minLongitude     = aLongitude - aLongitudeSpan;
    double maxLongitude     = aLongitude + aLongitudeSpan;
    
    NSMutableArray *preds   = [NSMutableArray array];
    
    [preds addObject:[NSPredicate predicateWithFormat:@"%K >= %f",
                      @"docLatitude",
                      minLatitude]];
    [preds addObject:[NSPredicate predicateWithFormat:@"%K <= %f",
                      @"docLatitude",
                      maxLatitude]];
    [preds addObject:[NSPredicate predicateWithFormat:@"%K >= %f",
                      @"docLongitude",
                      minLongitude]];
    [preds addObject:[NSPredicate predicateWithFormat:@"%K <= %f",
                      @"docLongitude",
                      maxLongitude]];
    
    DLog(@"-> search docs centered at %f, %f \nfor %f <= latitude <= %f and %f <= longitude <= %f",aLatitude, aLongitude,
         minLatitude, maxLatitude, minLongitude, maxLongitude);
    
    // search database
    OLCoreDataManagment *coreData = [[OLCoreDataManagment alloc] init];
    
    NSArray *tmp = [coreData listResultPred:iGRdFMOC
                                                  :@"docCityNameFull"
                                                  :@"ASC"
                                                  :[NSCompoundPredicate andPredicateWithSubpredicates:preds]
                                                  :GRdF_ENTITY_DOCUMENT];
 
    // build array with documents found
    for (GRDFDocument *doc in tmp)
    {
        [results addObject:[DocumentInterface documentDictForDocument:doc]];
    }

    
    [coreData freeMemory];
    MF_COCOA_RELEASE(coreData);
    
    preds               = nil;
    
    return [NSArray arrayWithArray:results];
}

#pragma mark - file management
+(NSString *)       documentPathForFileName:               (NSString *)    aDocFileName
                                withDefault:               (NSString *)    aDefault
{
    NSString *docPath =  [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
                            stringByAppendingPathComponent:kFolderRoot ]
                           // stringByAppendingPathComponent:kFolderDocument ]
                          stringByAppendingPathComponent:aDocFileName];
    
    NSString *defaultPath   =  [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
                                  stringByAppendingPathComponent:kFolderRoot ]
                                 // stringByAppendingPathComponent:kFolderDocument ]
                                stringByAppendingPathComponent:aDefault];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:docPath])
        return docPath ;
    else
        return defaultPath;
}

+ (NSString *) thumbnailPathForFileName: (NSString *)    aDocFileName
{
    
    NSString *thumbnailPath =  [[[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
                            stringByAppendingPathComponent:kFolderRoot ]
                           // stringByAppendingPathComponent:kFolderDocument ]
                          stringByAppendingPathComponent:[aDocFileName stringByDeletingPathExtension]]
                          stringByAppendingFormat:@"s.jpg"];

    return thumbnailPath;
}

#pragma mark - non public facility methods
+ (NSDictionary *) documentDictForDocument:(GRDFDocument *) aDocument
{
    DLog(@"-> begin");
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 @"", kDocumentDict_Reference,
                                 @"", kDocumentDict_Title,
                                 @"", kDocumentDict_Description,
                                 @"", kDocumentDict_CityName,
                                 @"", kDocumentDict_FileName,
                                 [NSNumber numberWithDouble:0], kDocumentDict_Latitude,
                                 [NSNumber numberWithDouble:0], kDocumentDict_Longitude,
                                 nil];
    if (aDocument)
    {
        [dict setObject:aDocument.docId             forKey:kDocumentDict_Id];
        [dict setObject:aDocument.docReference      forKey:kDocumentDict_Reference];
        [dict setObject:aDocument.docTitle          forKey:kDocumentDict_Title];
        [dict setObject:aDocument.docDescription    forKey:kDocumentDict_Description];
        [dict setObject:aDocument.docCityNameFull   forKey:kDocumentDict_CityName];
        [dict setObject:aDocument.docFileName       forKey:kDocumentDict_FileName];
        [dict setObject:aDocument.docLatitude       forKey:kDocumentDict_Latitude];
        [dict setObject:aDocument.docLongitude      forKey:kDocumentDict_Longitude];
    }
    
    return [NSDictionary dictionaryWithDictionary:dict];
}

@end
