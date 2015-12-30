//
//  GRDFCity.h
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 20/11/2014.
//  Copyright (c) 2014 Onatys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface GRDFCity : NSManagedObject

@property (nonatomic, retain) NSString * cityDepartment;
@property (nonatomic, retain) NSNumber * cityId;
@property (nonatomic, retain) NSNumber * cityLatitudeDeg;
@property (nonatomic, retain) NSNumber * cityLongitudeDeg;
@property (nonatomic, retain) NSString * cityNameFull;
@property (nonatomic, retain) NSString * cityNameSimple;
@property (nonatomic, retain) NSString * cityNameSoundex;
@property (nonatomic, retain) NSString * cityZipCode;

@end
