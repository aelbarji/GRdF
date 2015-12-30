//
//  OLGps.m
//  OnatysLibrary
//
//  Created by Damien Latournerie on 20/03/12.
//  Copyright (c) 2012 ONATYS. All rights reserved.
//

// #import "OLGpsAcquisition.h"
#import <CoreLocation/CoreLocation.h>
#import "OLGps.h"


@implementation OLGps

@synthesize clLocationManager   = _clLocationManager;
@synthesize clAccuracy          = _clAccuracy;
@synthesize lastGoodLocation    = _lastGoodLocation;
@synthesize eventsCount         = _eventsCount;
@synthesize isMonitorStarted    = _monitorStarted;
@synthesize delegate            = _delegate;
@synthesize gpsValues;

#pragma mark - initialization
// Set default gps configuration values
-(void) setDefaults
{
    NSUserDefaults *defaults    = [NSUserDefaults standardUserDefaults];
	NSString *stringValue       = [defaults objectForKey:kNsdKeyLocationMethods];
    _locationMethod             = ((stringValue==nil) ? kNsdKeyLocationMethodUpdate : stringValue );
    _assessDistance             = [defaults boolForKey:kNsdKeyAssessDistance];                          // default = NO if no previous saved value
    _assessAccuracy             = [defaults boolForKey:kNsdKeyAssessAccuracy];                          // default = NO if no previous saved value
    _threshold                  = [defaults doubleForKey:kNsdKeyThreshold];
    _desiredAccuracy            = [defaults doubleForKey:kNsdKeyAccuracy];
    
    if (_desiredAccuracy == 0) 
        _desiredAccuracy=kCLLocationAccuracyBest;
    
    _gpsEnabled                 = NO; // will be updated upon firt events
    _eventsCount                = 0;
    _monitorStarted             = NO;
}

// Save default values
-(void) saveDefaults
{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults]; 
    [defaults setObject : _locationMethod   forKey:kNsdKeyLocationMethods];    
    [defaults setDouble : _threshold        forKey:kNsdKeyThreshold];
    [defaults setDouble : _desiredAccuracy  forKey:kNsdKeyAccuracy];    
    [defaults setBool   : _assessAccuracy   forKey:kNsdKeyAssessAccuracy];
    [defaults setBool   : _assessDistance   forKey:kNsdKeyAssessDistance];
    [defaults synchronize];
}

// Initialization
-(OLGps *) initWithUserDefaults
{
    if (! (self = [super init]))
    {
        return nil;
    } 
    
    _clLocationManager             = [[CLLocationManager alloc] init];
    _clLocationManager.delegate    = self;
    _lastGoodLocation                   = [[CLLocation alloc] init];
    _locationServicesEnabled            = [CLLocationManager locationServicesEnabled];
    
    [self setDefaults];
    
    return self;
}

-(id) init {
	
	// Initialisation
	self = [super init];
	
	if (self != nil) {
		_clLocationManager					= [[[CLLocationManager alloc] init ] autorelease];
		_clLocationManager.desiredAccuracy	= kCLLocationAccuracyBest;
		// clLocationManager.desiredAccuracy	= kCLLocationAccuracyHundredMeters;
		_clLocationManager.delegate			= self;
		
	}

	return self;
}

#pragma mark - event assessement methods
-(BOOL) isAccuracyValid:(CLLocation *)newLocation
{
    if (_gpsEnabled)
    {
        if (_assessAccuracy)
            return (newLocation.horizontalAccuracy < _threshold);
        else
            return YES;
    }
    else 
        return NO;
}

-(BOOL) isDistanceValid:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    if (_assessDistance)
    {
        return ([newLocation distanceFromLocation:oldLocation] < _threshold);
    }
    else
        return YES;
}

#pragma mark - class methods
-(void) startMonitor
{
    
    // LOG
    DLog(@" -> begin");
    
    if (_locationServicesEnabled)
    {
        _clLocationManager.desiredAccuracy = _desiredAccuracy;
        _clLocationManager.distanceFilter = _threshold;
        _monitorStarted=YES;
        
        if ([_locationMethod isEqualToString: kNsdKeyLocationMethodUpdate])
            [_clLocationManager startUpdatingLocation];
        else 
            if ([_locationMethod isEqualToString: kNsdKeyLocationMethodChange])
                [_clLocationManager startMonitoringSignificantLocationChanges];
            else 
                _monitorStarted=NO;
    }
    else 
        _monitorStarted=NO;
    
    // LOG
    DLog(@" -> end");
    
}

-(void) stopMonitor
{
    
    // LOG
    DLog(@" -> begin");
    
    if (_monitorStarted)
    {
        if ([_locationMethod isEqualToString: kNsdKeyLocationMethodUpdate])
            [_clLocationManager stopUpdatingLocation];
        else 
            if ([_locationMethod isEqualToString: kNsdKeyLocationMethodChange])
                [_clLocationManager stopMonitoringSignificantLocationChanges];
        
        _monitorStarted=NO;
    }
    
    [_clLocationManager stopUpdatingLocation];
    
    // LOG
    DLog(@" -> end");
    
}


- (BOOL) isGpsEnabled
{
    return _gpsEnabled;
}

- (BOOL) isGpsAllowed
{
    return _locationServicesEnabled;
}


- (GPSValues) getCurrentValues
{
    GPSValues currentGpsValues;
    
    currentGpsValues.currentAltitude    = _lastGoodLocation.altitude;
    currentGpsValues.currentLatitude    = _lastGoodLocation.coordinate.latitude;
    currentGpsValues.currentLongitude   = _lastGoodLocation.coordinate.longitude;
    currentGpsValues.currentSpeed       =_lastGoodLocation.speed * 3.6;    
    currentGpsValues.currentCourse      = _lastGoodLocation.course;    
    
    return currentGpsValues;
}

- (double) getCurrentPrecision
{
    return _clAccuracy;
}


/*
-(void) startLocation 
{
    [ _clLocationManager startUpdatingLocation ];
}

-(void) stopLocation 
{
    [ _clLocationManager stopUpdatingLocation ];
}
*/

- (void) startLocationChanged 
{
    [ self init ];
    [ _clLocationManager startMonitoringSignificantLocationChanges ];
}


- (void) startGps : (int) _precision {
    
}

// Return GPS values
- (GPSValues) returnGpsValues {
	return gpsValues;
}

#pragma mark - CLLocationManagerDelegate implementation
// Authorization changes
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    _locationServicesEnabled = (status == kCLAuthorizationStatusAuthorizedAlways);
    if (!_locationServicesEnabled)
    {
        if (_monitorStarted)
            [self stopMonitor];
        // send notification back to owner to avoid further use of gps (and user prompt)
        [self performSelectorOnMainThread:@selector(tellTheDelegateLocationServicesUnavailable) withObject:nil waitUntilDone:NO];
    }
    //NSLog(@"Change Authorization Status %@",status);    
}

// Called always
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation { 
    /* in case we need to assess newLocation timestamp vs now
     
     NSDate *eventDate = newLocation.timestamp;
     NSTimeInterval howRecent = [eventDate timeIntervalSinceNstow];
     if (abs(howRecent) < 10.0) // 10 seconds -> to reconsider as NSUserDefaults value
     
     */
    _eventsCount++;
    _gpsEnabled=(newLocation.horizontalAccuracy >= 0);
    
    if ([self isAccuracyValid:newLocation] && [self isDistanceValid:newLocation fromLocation:oldLocation])
    {
        [_lastGoodLocation release];
        _lastGoodLocation = [newLocation retain];
        _clAccuracy = _lastGoodLocation.horizontalAccuracy;
        
        // Set new coordonates
        CLLocationCoordinate2D	loc	= [newLocation coordinate];
        
        gpsValues.currentAltitude   = newLocation.altitude;
        gpsValues.currentLatitude	= loc.latitude;
        gpsValues.currentLongitude	= loc.longitude;
        gpsValues.currentCourse		= newLocation.course;
        gpsValues.currentSpeed		= (newLocation.speed*3.6);      
    
    }
    
    // NSLog(@"gpsValues.currentLatitude:%.5f", gpsValues.currentLatitude);
	
}

// Location Failed
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error 
{ 	
    switch (error.code)
    {
        case kCLErrorDenied:
            if (_monitorStarted) [self stopMonitor];
            [self performSelectorOnMainThread:@selector(tellTheDelegateLocationServicesUnavailable) withObject:nil waitUntilDone:NO];
            
            break;
        case kCLErrorHeadingFailure:
            [self performSelectorOnMainThread:@selector(tellTheDelegateHeadingFailure) withObject:nil waitUntilDone:NO];
            break;
        case kCLErrorLocationUnknown:            
        default:
            NSLog(@"Fail with Error %@", error.description);
    }

}

// Heading Calibration
-(BOOL) locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager
{   
    return NO;
}

// Get location information
+ (BOOL)fetchLocationInfoToDictionary:(NSMutableDictionary *)_dictionary withLocation:(CLLocation *)_location
{
    if (_location == nil)
        FALSE;
    
    CLGeocoder *geocoder = [[[CLGeocoder alloc] init] autorelease];
    [geocoder reverseGeocodeLocation:_location completionHandler:^(NSArray *placemarks, NSError *error)
    {
         if ([placemarks count] > 0)
         {
             if (error)
                 [_dictionary setObject:error.description forKey:LOCATION_ERROR];
             else
             {
                 CLPlacemark *placemark = [placemarks objectAtIndex:0];
                 
                 NSLog(@"placemark.locality:%@", placemark.locality);
                 
                 if (placemark.location!=nil)
                     [_dictionary setObject:placemark.location forKey:LOCATION];
                 else
                     [_dictionary setObject:@"N/A" forKey:LOCATION];
                 
                 if (placemark.name!=nil)
                     [_dictionary setObject:placemark.name forKey:LOCATION_NAME];
                 else
                     [_dictionary setObject:@"N/A" forKey:LOCATION_NAME];
                 
                 if (placemark.country!=nil)
                     [_dictionary setObject:placemark.country forKey:LOCATION_COUNTRY];
                 else
                     [_dictionary setObject:@"N/A" forKey:LOCATION_COUNTRY];
                 
                 if (placemark.ISOcountryCode!=nil)
                     [_dictionary setObject:placemark.ISOcountryCode forKey:LOCATION_ISOCOUNTRYCODE];
                 else
                     [_dictionary setObject:@"N/A" forKey:LOCATION_ISOCOUNTRYCODE];
                 
                 if (placemark.region!=nil)
                     [_dictionary setObject:placemark.region forKey:LOCATION_REGION];
                 else
                     [_dictionary setObject:@"N/A" forKey:LOCATION_REGION];
                 
                 if (placemark.postalCode!=nil)
                     [_dictionary setObject:placemark.postalCode forKey:LOCATION_POSTALCODE];
                 else
                     [_dictionary setObject:@"N/A" forKey:LOCATION_POSTALCODE];
                 
                 if (placemark.subAdministrativeArea!=nil)
                     [_dictionary setObject:placemark.subAdministrativeArea forKey:LOCATION_SUBADMINISTRATIVEAREA];
                 else
                     [_dictionary setObject:@"N/A" forKey:LOCATION_SUBADMINISTRATIVEAREA];
                 
                 if (placemark.thoroughfare!=nil)
                     [_dictionary setObject:placemark.thoroughfare forKey:LOCATION_THROUGHFARE];
                 else
                     [_dictionary setObject:@"N/A" forKey:LOCATION_THROUGHFARE];
                 
                 if (placemark.subThoroughfare!=nil)
                     [_dictionary setObject:placemark.subThoroughfare forKey:LOCATION_SUBTHROUGHFARE];
                 else
                     [_dictionary setObject:@"N/A" forKey:LOCATION_SUBTHROUGHFARE];
                 
                 if (placemark.locality!=nil)
                     [_dictionary setObject:placemark.locality forKey:LOCATION_LOCALITY];
                 else
                     [_dictionary setObject:@"N/A" forKey:LOCATION_LOCALITY];
                 
                 if (placemark.subLocality!=nil)
                     [_dictionary setObject:placemark.subLocality forKey:LOCATION_SUBLOCALITY];
                 else
                     [_dictionary setObject:@"N/A" forKey:LOCATION_SUBLOCALITY];
                 
                 if (placemark.addressDictionary!=nil)
                     [_dictionary setObject:placemark.addressDictionary forKey:LOCATION_ADDRESS_DICTIONARY];
                 else
                     [_dictionary setObject:@"N/A" forKey:LOCATION_ADDRESS_DICTIONARY];
                 
                 // Send notification done
                 [[NSNotificationCenter defaultCenter] postNotificationName:OLGPS_NOTIFICATION_REVERSE_GEOCODE_DONE
                                                                     object:nil];
                 
             }
         }
    }
    ];
    return TRUE;
}

#pragma mark - memory management

-(void) dealloc
{
    [_lastGoodLocation release];
    [_clLocationManager release];
    [super dealloc];
}


#pragma mark - notification

- (void) tellTheDelegateLocationServicesUnavailable 
{
    [_delegate locationServicesUnavailable];   
}

- (void) tellTheDelegateHeadingFailure 
{
    [_delegate headingFailure];   
}

@end
