//
//  ResultMapViewController.m
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 19/11/2014.
//  Copyright (c) 2014 Onatys. All rights reserved.
//
#import <CoreLocation/CoreLocation.h>
// -- interface
#import "DocumentInterface.h"
// -- annotation
#import "GRdFMapAnnotation.h"

// result list datasource
#import "ResultListViewController.h"

#import "ResultMapViewController.h"

@interface ResultMapViewController () <MKMapViewDelegate,
                                        ResultListViewControllerDataSource>
{
    NSMutableArray *_currentAnnotations;
    BOOL userLocationUpdated;
}

@end

@implementation ResultMapViewController
#pragma mark - user interface actions


#pragma mark - public methods

#pragma mark - resultListViewController datasource notifications
- (NSValue *) regionCenterForResultListViewController:(ResultListViewController *)aController
{
    return self.currentRegionCenterValue;
}

- (NSValue *) regionSpanForResultListViewController:(ResultListViewController *)aController
{
    return self.currentRegionSpanValue;
}

#pragma mark - MkMapView delegate notifications
// -- region management
- (void)            mapView:(MKMapView *)       mapView
    regionDidChangeAnimated:(BOOL)              animated
{
    DLog(@"-> begin");
    
    if (!userLocationUpdated)
    {
        [self getData];
        userLocationUpdated = TRUE;
    }
    
    DLog(@"-> end");
}

- (void)            mapView:(MKMapView *)       mapView
      didUpdateUserLocation:(MKUserLocation *)  userLocation
{
    DLog(@"-> begin");
    
    if (!userLocationUpdated)
    {
        [self getData];
        userLocationUpdated = TRUE;
    }
    
    DLog(@"-> end");
}

// -- annotation management
- (void)               mapView:(MKMapView *)        mapView
                annotationView:(MKAnnotationView *) view
 calloutAccessoryControlTapped:(UIControl *)        control
{
    DLog(@"-> begin");
    
    if (_delegate)
    {
        GRdFMapAnnotation *annotation = view.annotation;
    
        DLog(@"annotation.fileName:%@", annotation.fileName);
        
        [_delegate resultMapViewController:self
                    documentSelectedWithId:[NSNumber numberWithDouble:annotation.documentId]
                               andFileName:annotation.fileName];
        
        annotation                  = nil;
    }
    
    DLog(@"-> end");
}


- (void) mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    DLog(@"-> begin");
    
    
    DLog(@"-> end");
}


- (MKAnnotationView *)mapView: (MKMapView *)        mapView
            viewForAnnotation: (id <MKAnnotation>)  annotation
{
    static NSString *identifier = @"GRdFMapAnnotation";
    if ([annotation isKindOfClass:[GRdFMapAnnotation class]])
    {
//        if pin instead of image
//        MKPinAnnotationView *annotationView = (MKPinAnnotationView *) [_mkvMap
//        MKAnnotationView *annotationView = (MKPinAnnotationView *) [_mkvMap dequeueReusableAnnotationViewWithIdentifier:identifier];
        MKAnnotationView *annotationView = [_mkvMap dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil)
        {
//        if pin instead of image
//            annotationView         = [[MKPinAnnotationView alloc] initWithAnnotation:
            annotationView          = [[[MKAnnotationView alloc] initWithAnnotation:annotation
                                                                   reuseIdentifier:identifier] autorelease];
        }
        else
        {
            annotationView.annotation = annotation;
        }
        
        annotationView.enabled      = YES;
        annotationView.canShowCallout = YES;
//        if pin instead of image
//        annotationView.pinColor = MKPinAnnotationColorGreen;
        annotationView.image        = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]
                                                                        pathForResource:@"icnGRdFPinPoint"
                                                                        ofType:@"png"]];

        annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        
        return annotationView;
    }
    
    return nil;
}


#pragma mark - private methods
- (void) configureUI
{
    DLog(@"-> begin");


    DLog(@"-> end");
}

- (void) localize
{
    DLog(@"-> begin");
    
    self.title              = NSLocalizedString(@"Result_Map",
                                                @"");

    DLog(@"-> end");
}

- (void) cleanMemory
{
    DLog(@"-> begin");
    
    MF_COCOA_RELEASE(_currentAnnotations);
    
    self.delegate                   = nil;
    self.currentRegionCenterValue   = nil;
    self.currentRegionSpanValue     = nil;
    
    DLog(@"-> end");
}


- (void) getData
{
    DLog(@"-> begin");
    
    // store current region definition
    self.currentRegionCenterValue   = [NSValue valueWithMKCoordinate:_mkvMap.region.center];
    self.currentRegionSpanValue     = [NSValue valueWithMKCoordinateSpan:_mkvMap.region.span];
    
    // fetch documents for region
    NSArray *docs = [DocumentInterface documentsWithinLatitudeSpan:_mkvMap.region.span.latitudeDelta
                                                  andLongitudeSpan:_mkvMap.region.span.longitudeDelta
                                                      fromLatitude:_mkvMap.region.center.latitude
                                                      andLongitude:_mkvMap.region.center.longitude];
    
    
    // step 1 : remove annotation if doesn't match new list of documents
    NSMutableArray *deleted = [NSMutableArray array];
    
    for (GRdFMapAnnotation *annotation in _currentAnnotations)
    {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"%K = %ld",
                             kDocumentDict_Id,
                             annotation.documentId];
        NSArray *tmp = [docs filteredArrayUsingPredicate:pred];
        
        BOOL isFound        = (tmp && (tmp.count > 0));
        
        if (!isFound)
        {
            // remove annotation from map
            [deleted addObject:annotation];
        }
        
        annotation  = nil;
    }
    
    if (deleted.count > 0)
    {
        [_mkvMap removeAnnotations:deleted];
        [_currentAnnotations removeObjectsInArray:deleted];
    }
    
    // step 2 : create new annotations from new list of documents
    for (NSDictionary *infos in docs)
    {
        NSPredicate *pred   = [NSPredicate predicateWithFormat:@"%K = %ld",
                               @"documentId",
                               [[infos objectForKey:kDocumentDict_Id] doubleValue]];
        
        NSArray *tmp        = [_currentAnnotations filteredArrayUsingPredicate:pred];
        
        BOOL isFound        = (tmp && (tmp.count > 0));
        
        if (!isFound)
        {
            // search if existing annotation for same city
            // ...
            
            // create new annotation
            GRdFMapAnnotation *annotation = [[GRdFMapAnnotation alloc] initWithInfos:infos];
            [_mkvMap addAnnotation:annotation];
            [_currentAnnotations addObject:annotation];
            
            [annotation release];
        }
        
        infos  = nil;
    }
    
    // warn delegate with new set of documents found
    if (_delegate)
        [_delegate resultMapViewController:self
            documentsFoundForCurrentRegion:docs.count];
    
    docs                    = nil;
    
    DLog(@"-> end");
}

#pragma mark - initialization and memory management
- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil
                           bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _currentAnnotations = [[NSMutableArray alloc] init];
    }
    
    return self;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self configureUI];
    [self localize];
    
    
    _mkvMap.userTrackingMode = MKUserTrackingModeFollowWithHeading;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) dealloc
{
    DLog(@"-> deallocating");
    
    [self cleanMemory];
    
    self.view   = nil;
    [super dealloc];
}

@end
