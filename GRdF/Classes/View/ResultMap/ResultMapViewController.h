//
//  ResultMapViewController.h
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 19/11/2014.
//  Copyright (c) 2014 Onatys. All rights reserved.
//
#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>

@protocol ResultMapViewControllerDelegate;

@interface ResultMapViewController : UIViewController
// class instance properties
@property (retain, nonatomic) NSValue *currentRegionCenterValue;
@property (retain, nonatomic) NSValue *currentRegionSpanValue;

@property (assign, nonatomic) id <ResultMapViewControllerDelegate> delegate;

// UI components
@property (retain, nonatomic) IBOutlet MKMapView *mkvMap;



@end


@protocol ResultMapViewControllerDelegate

- (void) resultMapViewController:(ResultMapViewController *)    aController
           documentSelectedWithId:(NSNumber *)                  aDocumentId
                      andFileName:(NSString *)                  aFileName;


- (void) resultMapViewController:(ResultMapViewController *)    aController
  documentsFoundForCurrentRegion:(NSInteger)                    aNbDocuments;

@end