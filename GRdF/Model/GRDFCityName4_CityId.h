//
//  GRDFCityName4_CityId.h
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 18/11/2014.
//  Copyright (c) 2014 Onatys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface GRDFCityName4_CityId : NSManagedObject

@property (nonatomic, retain) NSNumber * cityId;
@property (nonatomic, retain) NSString * cityNameFull;
@property (nonatomic, retain) NSString * prefix;

@end
