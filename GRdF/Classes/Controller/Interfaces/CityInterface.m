//
//  CityInterface.m
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 19/11/2014.
//  Copyright (c) 2014 Onatys. All rights reserved.
//

// -- relationships table (search purpose)
#define kCitySearchZipCode_Table      = @"GRDFCityZipCode_CityId"
#define kCitySearchPrefix3_Table      = @"GRDFCityName3_CityId"
#define kCitySearchPrefix4_Table      = @"GRDFCityName4_CityId"
#define kCitySearchPrefix5_Table      = @"GRDFCityName5_CityId"
#define kCitySearchPrefix6_Table      = @"GRDFCityName6_CityId"
#define kCitySearchPrefix7_Table      = @"GRDFCityName7_CityId"

// -- NSManaged entity
#import "GRDFCity.h"
#import "GRDFCityZipCode_CityId.h"
#import "GRDFCityName3_CityId.h"

#import "CityInterface.h"

@implementation CityInterface

#pragma mark - city search management
+ (NSArray *)         citiesForPrefix: (NSString *)     aPrefix
                      andPrefixLength: (NSInteger)      aSearchPrefixLength
                           andZipCode: (NSString *)     aZipCode
{
    DLog(@"-> begin");
    NSString *target = GRdF_ENTITY_CITY;
    
    switch (aSearchPrefixLength)
    {
        case 3:
            target = GRdF_ENTITY_NAME3_CITYID;
            break;
        case 4:
            target = GRdF_ENTITY_NAME4_CITYID;
            break;
        case 5:
            target = GRdF_ENTITY_NAME5_CITYID;
            break;
        case 6:
            target = GRdF_ENTITY_NAME6_CITYID;
            break;
        case 7:
            target = GRdF_ENTITY_NAME7_CITYID;
            break;
            
        default:
            break;
    }
    
    NSMutableArray *tmpNF   = [NSMutableArray array];
    
    if (aPrefix)
    {
        NSArray *cZC                    = [CityInterface cityIdsZipCode:aZipCode];
        BOOL isRestrictedToZC           = (cZC.count > 0);
        
        NSString *sPrefix               = [[aPrefix lowercaseString] stringByReplacingOccurrencesOfString:@"-"
                                                                                               withString:@" "];
        
        NSManagedObjectContext *moc     = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [moc setPersistentStoreCoordinator  : [iGRdFMOC persistentStoreCoordinator]];
        
        OLCoreDataManagment *coreData   = [[OLCoreDataManagment alloc] init];
        
        
        NSArray      *results           = [coreData listResultPred:moc
                                                                  :@"cityNameFull"
                                                                  :@"ASC"
                                                                  :[NSPredicate predicateWithFormat:
                                                                    @"%K like[c] %@",
                                                                    @"prefix",
                                                                    sPrefix]
                                                                  :target];
        if(results && [results count])
        {
            for (NSInteger idx = 0; idx < results.count; idx++)
            {
                // all search tables use same structure : consider CityName3 in all searches
                GRDFCityName3_CityId *cNF = [results objectAtIndex:idx];
                NSString *strNF         = [NSString stringWithFormat:@"%@|%@",
                                           cNF.cityNameFull,
                                           cNF.cityId];
                
                if (isRestrictedToZC)
                {
                    if ([cZC indexOfObject:cNF.cityId] != NSNotFound &&
                        [tmpNF indexOfObject:strNF] == NSNotFound)
                    {
                        [tmpNF addObject:strNF];
                    }
                }
                else
                {
                    
                    if ([tmpNF indexOfObject:strNF] == NSNotFound)
                        [tmpNF addObject:strNF];
                }

                
                strNF                   = nil;
                cNF                     = nil;
            }
            
            
            
        }
        
        [coreData freeMemory];
        MF_COCOA_RELEASE(coreData);
        MF_COCOA_RELEASE(moc);
        
    
        sPrefix                             = nil;
    }
    
    return [NSArray arrayWithArray:tmpNF];
    
}

+ (NSArray *)           citiesForZipCode: (NSString *)      aZipCode
{
    DLog(@"-> begin");
    
    NSMutableArray *tmpC   = [NSMutableArray array];
    
    if (aZipCode && aZipCode.length == 5)
    {
        NSManagedObjectContext *moc     = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [moc setPersistentStoreCoordinator  : [iGRdFMOC persistentStoreCoordinator]];
        
        OLCoreDataManagment *coreData   = [[OLCoreDataManagment alloc] init];
        
        
        NSArray      *results           = [coreData listResultPred:moc
                                                                  :@"cityNameFull"
                                                                  :@"ASC"
                                                                  :[NSPredicate predicateWithFormat:
                                                                    @"%K = %@",
                                                                    @"cityZipCode",
                                                                    aZipCode]
                                                                  :GRdF_ENTITY_ZIPCODE_CITYID];
        if(results && [results count])
        {
            for (NSInteger idx = 0; idx < results.count; idx++)
            {
                GRDFCityZipCode_CityId *cZC = [results objectAtIndex:idx];
                NSDictionary *cityInfos = [CityInterface cityDictForCityWithId:cZC.cityId];
                
                [tmpC addObject:[NSString stringWithFormat:@"%@|%@",
                                 [cityInfos objectForKey:kCityDict_NameFull],
                                 [cityInfos objectForKey:kCityDict_Id]]];
                
                cityInfos       = nil;
                cZC             = nil;
            }
        }
        
        [coreData freeMemory];
        MF_COCOA_RELEASE(coreData);
        MF_COCOA_RELEASE(moc);
   }
    
    
    return [NSArray arrayWithArray:tmpC];
}

+ (NSArray *)           cityIdsZipCode: (NSString *)      aZipCode
{
    DLog(@"-> begin");
    
    NSMutableArray *tmpC   = [NSMutableArray array];
    
    if (aZipCode && aZipCode.length == 5)
    {
        NSManagedObjectContext *moc     = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [moc setPersistentStoreCoordinator  : [iGRdFMOC persistentStoreCoordinator]];
        
        OLCoreDataManagment *coreData   = [[OLCoreDataManagment alloc] init];
        
        
        NSArray      *results           = [coreData listResultPred:moc
                                                                  :@"cityNameFull"
                                                                  :@"ASC"
                                                                  :[NSPredicate predicateWithFormat:
                                                                    @"%K = %@",
                                                                    @"cityZipCode",
                                                                    aZipCode]
                                                                  :GRdF_ENTITY_ZIPCODE_CITYID];
        if(results && [results count])
        {
            for (NSInteger idx = 0; idx < results.count; idx++)
            {
                GRDFCityZipCode_CityId *cZC = [results objectAtIndex:idx];
                NSDictionary *cityInfos = [CityInterface cityDictForCityWithId:cZC.cityId];
                
                [tmpC addObject:[cityInfos objectForKey:kCityDict_Id]];
                
                cityInfos       = nil;
                cZC             = nil;
            }
        }
        
        [coreData freeMemory];
        MF_COCOA_RELEASE(coreData);
        MF_COCOA_RELEASE(moc);
    }
    
    
    return [NSArray arrayWithArray:tmpC];
}


#pragma mark - zipCode search management
+ (NSArray *)          zipCodesForPrefix: (NSString *)      aPrefix
{
    DLog(@"-> begin");
    
    NSMutableArray *tmpZC   = [NSMutableArray array];
    
    if (aPrefix)
    {
        NSManagedObjectContext *moc     = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [moc setPersistentStoreCoordinator  : [iGRdFMOC persistentStoreCoordinator]];
        
        OLCoreDataManagment *coreData   = [[OLCoreDataManagment alloc] init];
        
        
        NSArray      *results           = [coreData listResultPred:moc
                                                                  :@"cityZipCode"
                                                                  :@"ASC"
                                                                  :[NSPredicate predicateWithFormat:
                                                                    @"%K BEGINSWITH[c] %@",
                                                                    @"cityZipCode",
                                                                    aPrefix]
                                                                  :GRdF_ENTITY_ZIPCODE_CITYID];
        if(results && [results count])
        {
            for (NSInteger idx = 0; idx < results.count; idx++)
            {
                GRDFCityZipCode_CityId *cZC = [results objectAtIndex:idx];
                
                NSString *strZC             = [NSString stringWithFormat:@"%@|%@",
                                               cZC.cityZipCode,
                                               cZC.cityZipCode];
                if ([tmpZC indexOfObject:strZC] == NSNotFound)
                    [tmpZC addObject:strZC];
                
                strZC                       = nil;
                cZC                         = nil;
            }
        }
        
        [coreData freeMemory];
        MF_COCOA_RELEASE(coreData);
        MF_COCOA_RELEASE(moc);

    }
    
    return [NSArray arrayWithArray:tmpZC];
}

#pragma mark - city detail management
+ (NSDictionary *)  cityDictForCityWithId: (NSNumber *)     aCityId
{
    DLog(@"-> begin");
    NSMutableDictionary *infos = [[NSMutableDictionary alloc]
                                  initWithDictionary:[CityInterface cityDictForCity:nil]];
    
    if (aCityId)
    {
        NSManagedObjectContext *moc         = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [moc setPersistentStoreCoordinator  : [iGRdFMOC persistentStoreCoordinator]];
        
        OLCoreDataManagment *coreData = [[OLCoreDataManagment alloc] init];

        
        NSArray      *results           = [coreData listResultPred:moc
                                                              :@""
                                                              :@""
                                                              :[NSPredicate predicateWithFormat:
                                                                @"%K == %@",
                                                                @"cityId",
                                                                aCityId]
                                                              :GRdF_ENTITY_CITY];
        if(results && [results count])
        {
            GRDFCity *city              = [results objectAtIndex:0];
            
            [infos removeAllObjects];
            [infos addEntriesFromDictionary:[CityInterface cityDictForCity:city]];
            
            city                        = nil;
        }
        
        
        [coreData freeMemory];
        MF_COCOA_RELEASE(coreData);
        MF_COCOA_RELEASE(moc);
    }
    
    NSDictionary *result = [NSDictionary dictionaryWithDictionary:infos];
    
    MF_COCOA_RELEASE(infos);
    
    return result;
}

#pragma mark - non public facility methods

+ (NSDictionary *) cityDictForCity:(GRDFCity *) aCity
{
    DLog(@"-> begin");
    
    NSMutableDictionary *infos = [[NSMutableDictionary alloc] initWithObjects:@[[NSNumber numberWithInteger:-1],
                                                                                @"",
                                                                                @"",
                                                                                @"",
                                                                                @"",
                                                                                @"",
                                                                                @"",
                                                                                @""]
                                                                      forKeys:@[kCityDict_Id,
                                                                                kCityDict_NameFull,
                                                                                kCityDict_NameSimple,
                                                                                kCityDict_NameSoundex,
                                                                                kCityDict_ZipCode,
                                                                                kCityDict_Department,
                                                                                kCityDict_Longitude,
                                                                                kCityDict_Latitude]];
    
    if (aCity)
    {
        [infos setObject:aCity.cityId           forKey:kCityDict_Id];
        [infos setObject:aCity.cityNameFull     forKey:kCityDict_NameFull];
        [infos setObject:aCity.cityNameSimple   forKey:kCityDict_NameSimple];
        [infos setObject:aCity.cityNameSoundex  forKey:kCityDict_NameSoundex];
        [infos setObject:aCity.cityZipCode      forKey:kCityDict_ZipCode];
        [infos setObject:aCity.cityDepartment   forKey:kCityDict_Department];
        [infos setObject:aCity.cityLongitudeDeg forKey:kCityDict_Longitude];
        [infos setObject:aCity.cityLatitudeDeg  forKey:kCityDict_Latitude];
    }
    
    NSDictionary *result = [NSDictionary dictionaryWithDictionary:infos];
    
    MF_COCOA_RELEASE(infos);
    
    return result;

}

@end
