//
//  GRdF.h
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 19/11/13.
//  Copyright (c) 2013 Onatys. All rights reserved.
//

#ifndef GRdF_GRdF_h
#define GRdF_GRdF_h


#define IS_TRUE             @"TRUE"
#define IS_FALSE            @"FALSE"


#ifdef DEBUG
#       define DLog(fmt, ...) NSLog((@"%s (Line %d)" fmt),   __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#       define DError(fmt, ...) NSLog((@"%s (Line %d) " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#       define DLog(...)
#       define DError(...);
#endif

#define MF_COCOA_RELEASE(x)\
if((x)!=nil) {		\
[(x)release],(x)=nil; \
}


#define MF_C_FREE(x)\
if((x)!=NULL) {		\
free((x)),(x)=NULL; \
}


#import "AppDelegate.h"

// -----------------    User interface constants   ----------------

// UI common definition
// Font
#define GRdF_FONT                                         @"Helvetica-Neue"
#define GRdF_BUTTON_FONT_SIZE                             15

#define GRdF_BUTTON_DEFAULT_BACKGROUND_NORMAL             [UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"bkgButtonDefault" ofType: @"png"]]
#define GRdF_BUTTON_DEFAULT_BACKGROUND_HIGHLIGHT          [UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"bkgButtonDefaultSel" ofType: @"png"]]

#define GRdF_BUTTON_CONFIRM_BACKGROUND_NORMAL             [UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"bkgButtonConfirm" ofType: @"png"]]
#define GRdF_BUTTON_CONFIRM_BACKGROUND_HIGHLIGHT          [UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"bkgButtonConfirmSel" ofType: @"png"]]

#define GRdF_BUTTON_ACTION_BACKGROUND_NORMAL             [UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"bkgButtonAction" ofType: @"png"]]
#define GRdF_BUTTON_ACTION_BACKGROUND_HIGHLIGHT          [UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"bkgButtonActionSel" ofType: @"png"]]

#define GRdF_BUTTON_DELETE_BACKGROUND_NORMAL              [UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"bkgButtonDelete" ofType: @"png"]]
#define GRdF_BUTTON_DELETE_BACKGROUND_HIGHLIGHT           [UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"bkgButtonDeleteSel" ofType: @"png"]]

// Colors
// Mercury (232, 232, 232)
#define GRdF_LABEL_BACKGROUND_COLOR           [UIColor colorWithRed:232./255. green:232./255. blue:232./255.  alpha:1.]
// Tungten (51, 51,51)
#define GRdF_LABEL_TEXT_COLOR                 [UIColor colorWithRed:51./255.  green:51./255.  blue:51./255.   alpha:1.]

#define GRdF_BG_TEXT_FIELD_COLOR              [UIColor colorWithRed:250./255. green:250./255. blue:250./255.  alpha:1.0]
#define GRdF_TEXT_FIELD_COLOR                 [UIColor colorWithRed:50./255. green:50./255. blue:50./255.  alpha:1.0]
#define GRdF_TEXT_FIELD_SIZE                  15.0


// trace web service requests (post and response)
#define GRdF_SRV_WS_TRACEREQUEST                    TRUE

// search radius default/max values (km)
#define GRdF_SEARCH_RADIUS_DEFAULT                  50
#define GRdF_SEARCH_RADIUS_MAX                      100


// server's available environments
// #define GRdF_ENVIRONMENT_DEV                     @"alpha"
// #define GRdF_ENVIRONMENT_PREPROD                    @"preprod"
#define GRdF_ENVIRONMENT_PROD                     @"prod"

#define OMBS_DATABASE_FILE                          @"iPadData.sqlite"

// default server prefix for url and docroot for files synchronisation
#ifdef GRdF_ENVIRONMENT_DEV
    #define GRdF_SRV_WS_PREFIX                      @"http://apigrdfdev.onatys.com/00008/ws"       // ws prefix
    #define GRdF_SRV_DOCROOT                        @"http://apigrdfdev.onatys.com/00008"          // dev server docroot for file download
    #define GRdf_USERNAME                           @"grdf@groupehn.com"
    #define GRdf_PASSWORD                           @"Vv2WsO8uYIV1"
#else
#ifdef GRdF_ENVIRONMENT_PREPROD
    #define GRdF_SRV_WS_PREFIX                      @"http://www.onatys.com/grdf/v1.0/ws"       // ws prefix
    #define GRdF_SRV_DOCROOT                        @"http://www.onatys.com/grdf/v1.0/files"    // dev for file download
    #define GRdf_USERNAME                           @"grdfpreprod@groupehn.com"
    #define GRdf_PASSWORD                           @"123456"
#else
    #define GRdF_SRV_WS_PREFIX                      @"http://apigrdf.onatys.com/00002/ws"       // ws prefix
    #define GRdF_SRV_DOCROOT                        @"http://apigrdf.onatys.com/00002"    // dev
    #define GRdf_USERNAME                           @"grdf@groupehn.com"
    #define GRdf_PASSWORD                           @"uIJDJ99MQaiJ"
#endif
#endif

// application update
#define OL_UPDATE_INFO_URL_GRdF                     @"http://www.onatys.com/appversions/grdf.php"
#define OL_UPDATE_URL_GRdF                          @"http://www.onatys.com/apptest/grdf-main.php"


// common notifications
#define GRdF_SYNCHRO_CLOSE_NOTIFICATION             @"closeSynchro"


// macros
#define iGRdFDelegate        (AppDelegate *)              [[UIApplication sharedApplication] delegate]
// global properties (singleton)
#define iGRdFMOC             (NSManagedObjectContext *)   [iGRdFDelegate  managedObjectContext]
#define iGRdFGps             (OLGps *)                    [iGRdFDelegate  olGps]
#define iGRdFDecimalSep      (NSString *)                           [iGRdFDelegate          decimalSeparator]

// entity and entity status management (database synchronization)
#define GRdF_ENTITY_DOCUMENT                        @"GRDFDocument"
#define GRdF_ENTITY_CITY                            @"GRDFCity"
#define GRdF_ENTITY_ZIPCODE_CITYID                  @"GRDFCityZipCode_CityId"
#define GRdF_ENTITY_NAME3_CITYID                    @"GRDFCityName3_CityId"
#define GRdF_ENTITY_NAME4_CITYID                    @"GRDFCityName4_CityId"
#define GRdF_ENTITY_NAME5_CITYID                    @"GRDFCityName5_CityId"
#define GRdF_ENTITY_NAME6_CITYID                    @"GRDFCityName6_CityId"
#define GRdF_ENTITY_NAME7_CITYID                    @"GRDFCityName7_CityId"

// synchronization common definitions
#define GRdF_DEFAULT_DATE_FORMAT                    @"yyyy/MM/dd HH:mm:ss"
#define FULL_SYNC_DATE_FORMAT                       @"yyyyMMdd"

#define kEntitySyncAttribute                        @"syncStatus"

#define kSyncDbStatusPendingDelete                  4
#define kSyncDbStatusPendingCreation                3
#define kSyncDbStatusPendingUpdate                  2
#define kSyncDbStatusDone                           0    // default value in coredata


// User defaults
#define kNSUserDefaultsEmail                        @"email"
#define kNSUserDefaultsPassword                     @"password"
#define kNSUserDefaultsEmailBody                    @"emailBody"
#define kNSUserDefaultsSynchroTimeStamp             @"timestampSynchro"
#define kNSUserDefaultsFirstUse                     @"firstUse"
#define kNSUserDefaultsPreferedLanguage             @"language"
#define kNSUserDefaultsLastLogin                    @"kNSUserDefaultsLastLogin"
#define kNSUserDefaultsLastSync                     @"kNSUserDefaultsLastSync"

#define kNSUserDefaultsFullSync                     @"lastFullSyncCompleted"    // 10000001

// user interface / navigation constants
#define kControllerAction_Back                      0
#define kControllerAction_Save                      1
#define kControllerAction_Continue                  2
#define kControllerAction_New                       3
#define kControllerAction_NewRoot                   4
#define kControllerAction_Delete                    5
#define kControllerAction_Advanced                  6
#define kControllerAction_Basic                     7
#define kControllerAction_None                      99


// user interface / navigation constants
#define kGUIModeReadOnly                        0    // information will be readonly in viewController
#define kGUIModeUpdate                          1    // information will be updatable. Action available is "save" and user remains on current controller
#define kGUIModePassThrough                     2    // new entity : information will be pre-filled with default value. Action available is "continue" to proceed with user entry on next controller
#define kGUIModePopover                         3    // new entity : same as passThrough but interface is called from popoverController (ex: new zone when adding product to project) -> continue action will save, notify delegate and dissmiss, cancel action available to dissmiss without saving



// application folders
#define kFolderRoot                             @"files"
#define kFolderDocument                         @"document"


// common dictionaries' keys
#define kUserDict_Id                            @"userId"
#define kUserDict_FirstName                     @"userFirstName"
#define kUserDict_LastName                      @"userLastName"
#define kUserDict_Email                         @"userEmail"
#define kUserDict_Pwd                           @"userPassword"

@interface NSDate (GRdF)

- (BOOL)      isSameDay:(NSDate *) aDate;
- (NSInteger) hour;
- (NSInteger) minute;

- (NSString *) normalizedEventString;

- (NSString *) intervalStringSince1970GMT;

- (BOOL)     belongsToPeriod:(NSDate *) aStartDate
                            :(NSDate *)   aEndDate;

+ (NSDate *) dateWithIntervalSince1970GMT:(NSTimeInterval) aInterval;

+ (NSInteger) minutesBetweenStart:(NSDate *) aStartDate
                           andEnd:(NSDate *) aEndDate;

@end
@implementation NSDate (GRdF)

#pragma mark - static class methods

+ (NSDate *) dateWithIntervalSince1970GMT:(NSTimeInterval) aInterval
{
    NSTimeInterval timeZoneOffset   = [[NSTimeZone defaultTimeZone]
                                       secondsFromGMT];
    return [NSDate dateWithTimeIntervalSince1970:(aInterval + timeZoneOffset)];
}

+ (NSInteger) minutesBetweenStart:(NSDate *) aStartDate
                           andEnd:(NSDate *) aEndDate
{
    NSCalendar *curCalendar         = [NSCalendar autoupdatingCurrentCalendar];
    NSDateComponents *components    = [curCalendar components:NSCalendarUnitMinute
                                                     fromDate:aStartDate
                                                       toDate:aEndDate
                                                      options:0];
    NSInteger diff                  = components.minute;
    
    return diff;
}



#pragma mark - public instance methods
- (BOOL) isSameDay:(NSDate *) aDate
{
    NSCalendar *curCalendar =  [NSCalendar autoupdatingCurrentCalendar];
    NSDateComponents *components = [curCalendar components:
                                    NSCalendarUnitYear  |
                                    NSCalendarUnitMonth |
                                    NSCalendarUnitDay
                                                  fromDate:self];
    
    NSInteger selfValue     = components.year*10000 +
    components.month*100 +
    components.day;
    components              = [curCalendar components:
                               NSCalendarUnitYear  |
                               NSCalendarUnitMonth |
                               NSCalendarUnitDay
                                             fromDate:aDate];
    
    NSInteger dateValue     = components.year*10000 +
    components.month*100 +
    components.day;
    
    return (dateValue == selfValue);
}

- (NSInteger) hour
{
    NSCalendar *curCalendar =  [NSCalendar autoupdatingCurrentCalendar];
    NSDateComponents *components = [curCalendar components:
                                    NSCalendarUnitHour
                                                  fromDate:self];
    
    NSInteger result = components.hour;
    
    return result;
}


- (NSInteger) minute
{
    NSCalendar *curCalendar =  [NSCalendar autoupdatingCurrentCalendar];
    NSDateComponents *components = [curCalendar components:
                                    NSCalendarUnitMinute
                                                  fromDate:self];
    
    NSInteger result = components.minute;
    
    return result;
}

// returns normalized string
// (dd-MMM-yyyy EE HH:00 -> 12-Jan-2013 Jeu. 10:22 )
- (NSString *) normalizedEventString
{
    NSDateFormatter *formatter  = [[NSDateFormatter alloc]init];
    [formatter    setDateFormat : @"dd-MM-yyyy EE HH:mm"];
    
    NSString  *result           = [NSString  stringWithFormat:@"%@",
                                   [formatter stringFromDate:self]];
    
    MF_COCOA_RELEASE(formatter);
    
    DLog(@"normalizedEventString: %@  - for date: %@",
         result,
         self);
    
    return result;
}


// returns string based on number of seconds since 1970 GMT
- (NSString *) intervalStringSince1970GMT
{
    NSTimeInterval timeZoneOffset   = [[NSTimeZone defaultTimeZone]
                                       secondsFromGMT];
    
    NSString *result                = [NSString  stringWithFormat:@"%.0f",
                                       [self timeIntervalSince1970]- timeZoneOffset];
    
    DLog(@"secondsSince1970GMTForDate:%@  - %@  - timezone offset:%f",
         self,
         result,
         timeZoneOffset);
    
    return result;
}

- (BOOL)     belongsToPeriod:(NSDate *) aStartDate
                            :(NSDate *)   aEndDate
{
    NSUInteger  compStart = [self compare:aStartDate];
    NSUInteger  compEnd   = [self compare:aEndDate];
    
    BOOL bResult = ( (compStart== NSOrderedDescending  ||
                      compStart== NSOrderedSame)           &&
                    (compEnd  == NSOrderedAscending ||
                     compEnd  == NSOrderedSame) );
    
    return bResult;
}



@end


@interface NSFileManager(GRdF)

+ (uint64_t) freeSpace;
+ (uint64_t) totalSpace;

@end

@implementation NSFileManager(GRdF)

+ (uint64_t) freeSpace
{
    float result    = 0.0f;
    NSError *error  = nil;
    NSArray *paths  = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject]
                                                                                       error: &error];
    
    if (dictionary)
    {
        NSNumber *fileSystemFreeSizeInBytes = [dictionary objectForKey: NSFileSystemFreeSize];
        result = [fileSystemFreeSizeInBytes floatValue];
        DLog(@"free bytes: %@", fileSystemFreeSizeInBytes);
    } else
    {
        //Handle error
    }  
    return result;
}

+ (uint64_t) totalSpace
{
    float result    = 0.0f;
    NSError *error  = nil;
    NSArray *paths  = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject]
                                                                                       error: &error];
    
    if (dictionary)
    {
        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];
        result = [fileSystemSizeInBytes unsignedLongLongValue];
        DLog(@"free bytes: %@", fileSystemSizeInBytes);
    } else
    {
        //Handle error
    }
    return result;
}


@end


#endif
