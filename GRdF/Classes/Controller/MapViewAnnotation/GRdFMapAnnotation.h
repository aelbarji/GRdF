//
//  GRdFMapAnnotation.h
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 21/11/2014.
//  Copyright (c) 2014 Onatys. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface GRdFMapAnnotation : NSObject <MKAnnotation>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy)     NSString *title;
@property (nonatomic, copy)     NSString *subtitle;
@property (nonatomic, assign)   double   documentId;
@property (nonatomic, copy)     NSString *fileName;

// -- public instance methods
- (id) initWithInfos:(NSDictionary *) aInfos;

@end
