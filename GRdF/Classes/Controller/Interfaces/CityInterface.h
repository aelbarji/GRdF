//
//  CityInterface.h
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 19/11/2014.
//  Copyright (c) 2014 Onatys. All rights reserved.
//

typedef enum {
    GRdFCitySearchPrefixLength_3 = 3,
    GRdFCitySearchPrefixLength_4,
    GRdFCitySearchPrefixLength_5,
    GRdFCitySearchPrefixLength_6,
    GRdFCitySearchPrefixLength_7
} GRdFCitySearch_PrefixLength;

typedef NSInteger _GRdFCitySearch_PrefixLength;

#define kCityDict_Id            @"cityId"
#define kCityDict_NameFull      @"cityNameFull"
#define kCityDict_NameSimple    @"cityNameSimple"
#define kCityDict_NameSoundex   @"cityNameSoundex"
#define kCityDict_ZipCode       @"cityZipCode"
#define kCityDict_Department    @"cityDepartment"
#define kCityDict_Longitude     @"cityLongitude"
#define kCityDict_Latitude      @"cityLatitude"

#import <Foundation/Foundation.h>

@interface CityInterface : NSObject


// -- city search management
+ (NSArray *)            citiesForPrefix: (NSString *)      aPrefix
                         andPrefixLength: (NSInteger)       aSearchPrefixLength
                              andZipCode: (NSString *)      aZipCode;

+ (NSArray *)           citiesForZipCode: (NSString *)      aZipCode;

// -- zipCode search management
+ (NSArray *)          zipCodesForPrefix: (NSString *)      aPrefix;

// -- city detail management
+ (NSDictionary *)  cityDictForCityWithId: (NSNumber *)     aCityId;

@end
