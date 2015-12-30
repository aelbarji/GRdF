//
//  SyncGRDFDocument.h
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 20/11/2014.
//  Copyright (c) 2014 Onatys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface SyncGRDFDocument : NSManagedObject

@property (nonatomic, retain) NSString * docCityNameFull;
@property (nonatomic, retain) NSString * docDescription;
@property (nonatomic, retain) NSString * docFileName;
@property (nonatomic, retain) NSNumber * docId;
@property (nonatomic, retain) NSNumber * docLatitude;
@property (nonatomic, retain) NSNumber * docLongitude;
@property (nonatomic, retain) NSString * docTitle;
@property (nonatomic, retain) NSString * docReference;

@end
