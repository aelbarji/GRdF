//
//  GRdFMapAnnotation.m
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 21/11/2014.
//  Copyright (c) 2014 Onatys. All rights reserved.
//

// -- interface
#import "DocumentInterface.h"

#import "GRdFMapAnnotation.h"

@implementation GRdFMapAnnotation


#pragma mark - public methods
- (id) initWithInfos:(NSDictionary *)aInfos
{
    if (!(self = [super init]))
    {
        return nil;
    }

    if (aInfos)
    {
        // Coordinate
        double latitude     = [[aInfos objectForKey:kDocumentDict_Latitude] doubleValue];
        double longitude    = [[aInfos objectForKey:kDocumentDict_Longitude] doubleValue];
        
        _coordinate         = CLLocationCoordinate2DMake(latitude, longitude);
        
        // title
        self.title          = [NSString stringWithFormat:@"%@ - %@",
                               [aInfos objectForKey:kDocumentDict_Reference],
                               [aInfos objectForKey:kDocumentDict_CityName]];
        
        // subTitle
        self.subtitle       = [NSString stringWithFormat:@"%@",
                               [aInfos objectForKey:kDocumentDict_Description]];
        
        // fileName
        self.fileName       = [aInfos objectForKey:kDocumentDict_FileName];
        
        // document id
        self.documentId     = [[aInfos objectForKey:kDocumentDict_Id] doubleValue];
        
        
    }
    else
    {
        self.documentId     = -1;
        self.title          = @"?";
        self.subtitle       = @"";
    }
    
    return self;
}


#pragma mark - initialization and memory management
- (void) dealloc
{
    DLog(@"-> deallocating");
    
    self.title      = nil;
    self.subtitle   = nil;
    self.fileName   = nil;
    
    [super dealloc];
}

- (id) init
{
    if (! (self = [super init]))
    {
        return nil;
    }
    
    return self;
}
@end
