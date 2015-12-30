//
//  OLInternetD.h
//  OnatysLibrary
//
//  Created by Damien Latournerie on 05/03/12.
//  Copyright (c) 2012 ONATYS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <SystemConfiguration/SystemConfiguration.h>


#define OL_INTERNET_NOTIFICATION_SUCCESS    @"OL_INTERNET_NOTIFICATION_SUCCESS"
#define OL_INTERNET_NOTIFICATION_ERROR      @"OL_INTERNET_NOTIFICATION_ERROR"

// #define DEBUG_OLINTERNET        FALSE
/*
enum {
    WSMethodGET = 0,
    WSMethodPOST
} typedef WSMethodType;
*/
@interface OLInternetD : NSObject
{
    NSString            *responseString;
    NSError             *responseError;
    BOOL                responseReceived;
}

@property (assign, nonatomic) BOOL traceRequests;

- (NSString *)  returnResponseString;
- (NSError *)   returnResponseError;
- (BOOL)        returnResponseReceived;
+ (BOOL)        hasConnectivity;
+ (BOOL)        connectionIsWifi;

- (void) uploadImage    : (UIImage *)           image 
                        : (NSString *)          _url
                        : (NSString *)          _fileName;
- (void) uploadFile     : (NSString *)          _url
                        : (NSString *)          _fileName
                        : (NSString *)          _contentType
                        : (NSString *)          _key;
- (void) sendPostData   : (NSString *)          _url 
                        : (NSArray *)           _postLabel 
                        : (NSArray *)           _postValues 
                        : (BOOL)                _isAsynchronous;
- (BOOL) sendPostDataJson : (NSString *) _url
                          : (NSDictionary *) _postDict;
- (BOOL) sendGetDataJson : (NSString *) _url : (NSDictionary *) _postDict;
/*
- (void) sendGetData    : (NSString *)          _url 
                        : (BOOL)                _isAsynchronous;
*/

@end
