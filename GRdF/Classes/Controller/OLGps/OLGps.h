//
//  OLGps.h
//  OnatysLibrary
//
//  Created by Damien Latournerie on 20/03/12.
//  Copyright (c) 2012 ONATYS. All rights reserved.
//  ------------------------------------------------
//  Last update : 24/05/12 by JPhB: 
//      - add userdefaults configuration capabilities
//      - deprecate previous monitor start/stop method
//      - add protocol to warn delegate in case of location failure or service unavailable
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h> 
#import <CoreLocation/CLLocationManagerDelegate.h>

#define kNsdKeyLocationMethods              @"location method"
#define kNsdKeyThreshold                    @"threshold"
#define kNsdKeyAccuracy                     @"desired accuracy"
#define kNsdKeyAssessDistance               @"assess distance"
#define kNsdKeyAssessAccuracy               @"assess accuracy"
#define kNsdKeyLocationMethodUpdate         @"update"
#define kNsdKeyLocationMethodChange         @"significant change"

#define LOCATION                            @"Location"
#define LOCATION_ERROR                      @"Error"
#define LOCATION_NAME                       @"Name"
#define LOCATION_COUNTRY                    @"Country"
#define LOCATION_ISOCOUNTRYCODE             @"ISOCountryCode"
#define LOCATION_REGION                     @"Region"
#define LOCATION_POSTALCODE                 @"PostalCode"
#define LOCATION_ADMINISTATIVEAREA          @"Area"
#define LOCATION_SUBADMINISTRATIVEAREA      @"SubArea"
#define LOCATION_THROUGHFARE                @"Street"
#define LOCATION_SUBTHROUGHFARE             @"NO."
#define LOCATION_LOCALITY                   @"City"
#define LOCATION_SUBLOCALITY                @"District"
#define LOCATION_ADDRESS_DICTIONARY         @"AddressDictionary"

#define OLGPS_NOTIFICATION_REVERSE_GEOCODE_DONE @"OLGPS_NOTIFICATION_REVERSE_GEOCODE_DONE"

typedef struct 
{
    double              currentAltitude;
	double				currentLatitude;
	double				currentLongitude;
	double				currentCourse;
	int					currentSpeed;
} GPSValues;

@protocol OLGpsDelegate;

@interface OLGps : NSObject <CLLocationManagerDelegate> {
    
//    @public 
    
    CLLocationManager       *_clLocationManager;
	
	GPSValues               gpsValues;
    
    CLLocationAccuracy      _clAccuracy;
    CLLocation              *_lastGoodLocation;
    
    // event notification method & rules
    NSString                *_locationMethod;
    BOOL                    _assessDistance;
    BOOL                    _assessAccuracy;
    CLLocationDistance      _threshold;
    CLLocationAccuracy      _desiredAccuracy;
    
    // attributes
    NSInteger               _eventsCount;
    BOOL                    _monitorStarted;
    BOOL                    _locationServicesEnabled;
    BOOL                    _gpsEnabled;
    
    // delegate 
    id<OLGpsDelegate> _delegate;

}
@property (assign, nonatomic)       GPSValues           gpsValues;

@property (retain, nonatomic)       CLLocationManager   *clLocationManager;
@property (readonly, nonatomic)     CLLocationAccuracy  clAccuracy;
@property (retain, nonatomic)       CLLocation          *lastGoodLocation;
@property (readonly, nonatomic)     NSInteger           eventsCount;
@property (readonly, nonatomic)     BOOL                isMonitorStarted;
@property (nonatomic, assign)       id<OLGpsDelegate> delegate;

/**
 * Initialise GPS instance
 *
 * @return OLGps instance
 *
 */
- (OLGps *) initWithUserDefaults;

/**
 * Start GPS
 *
 */
- (void)        startMonitor;

/**
 * Stop GPS
 *
 */
- (void)        stopMonitor;

/**
 * Return current GPS values
 *
 * @return GPSValues current GPS values
 *
 */
- (GPSValues)   getCurrentValues;

/**
 * Return current GPS precision
 *
 * @return double current GPS precision (m)
 *
 */
- (double)      getCurrentPrecision;

/**
 * Check if GPS is enabled
 *
 * @return (TRUE/FALSE)
 *
 */
- (BOOL)        isGpsEnabled;

/**
 * Check if GPS is allowed for the application
 *
 * @return (TRUE/FALSE)
 *
 */
- (BOOL)        isGpsAllowed;

/**
 * Reverse geocode position
 *
 * @return NSMutableDictionary Address details
 *
 */
+ (BOOL)fetchLocationInfoToDictionary:(NSMutableDictionary *)_dictionary withLocation:(CLLocation *)_location;

// Deprecated
- (void)        startLocationChanged;
- (GPSValues )	returnGpsValues __attribute__((deprecated));

@end

@protocol OLGpsDelegate <NSObject>
- (void) locationServicesUnavailable;
- (void) headingFailure;
@end
