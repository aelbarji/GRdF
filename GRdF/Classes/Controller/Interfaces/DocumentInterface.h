//
//  DocumentInterface.h
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 18/11/2014.
//  Copyright (c) 2014 Onatys. All rights reserved.
//

#define kDocumentDict_Id            @"docId"
#define kDocumentDict_Reference     @"docReference"
#define kDocumentDict_Title         @"docTitle"
#define kDocumentDict_Description   @"docDescription"
#define kDocumentDict_FileName      @"docFileName"
#define kDocumentDict_Longitude     @"docLongitude"
#define kDocumentDict_Latitude      @"docLatitude"
#define kDocumentDict_CityName      @"docCityName"

#import <Foundation/Foundation.h>

@interface DocumentInterface : NSObject


// -- document search management
+ (NSArray *) documentsWithinLatitudeSpan: (double)     aLatitudeSpan
                         andLongitudeSpan: (double)     aLongitudeSpan
                             fromLatitude: (double)     aLatitude
                             andLongitude: (double)     aLongitude;

// -- file management
+ (NSString *)  documentPathForFileName: (NSString *)    aDocFileName
                            withDefault: (NSString *)    aDefault;

+ (NSString *) thumbnailPathForFileName: (NSString *)    aDocFileName;

@end
