//
//  OLInternetD.m
//  OnatysLibrary
//
//  Created by Damien Latournerie on 05/03/12.
//  Copyright (c) 2012 ONATYS. All rights reserved.
//

#import "OLInternetD.h"
#import "SBJsonParser.h"
//#import "JSONKit.h"
#import "OLCheckRights.h"

@interface OLInternetD() <NSURLConnectionDelegate>

@end

@implementation OLInternetD
@synthesize traceRequests;

- (NSString *) returnResponseString
{
    return responseString;
}

- (NSError *) returnResponseError
{
    return responseError;
}

- (BOOL) returnResponseReceived
{
    return responseReceived;
}


#pragma mark - connectivity checking
+(BOOL) connectionIsWifi
{
    // Check rights
//    [ OLCheckRights checkRights ];
    
 	Reachability *r = [Reachability reachabilityWithHostName:@"www.google.com"];
                       
    NetworkStatus internetStatus = [r currentReachabilityStatus];
    
    bool result = false;
                       
    if (internetStatus == ReachableViaWiFi)
    {
        result = true;
    }
                       
    return result;

}

+(BOOL) hasConnectivity
{
    // Check rights
//    [ OLCheckRights checkRights ];
    
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);
    if(reachability != NULL) {
        //NetworkStatus retVal = NotReachable;
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(reachability, &flags)) {
            if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
            {
                // if target host is not reachable
                return NO;
            }
            
            if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
            {
                // if target host is reachable and no connection is required
                //  then we'll assume (for now) that your on Wi-Fi
                return YES;
            }
            
            
            if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
                 (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
            {
                // ... and the connection is on-demand (or on-traffic) if the
                //     calling application is using the CFSocketStream or higher APIs
                
                if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
                {
                    // ... and no [user] intervention is needed
                    return YES;
                }
            }
            
            if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
            {
                // ... but WWAN connections are OK if the calling application
                //     is using the CFNetwork (CFSocketStream?) APIs.
                return YES;
            }
        }
    }
    
    return NO;
}


#pragma mark Upload image
- (void) uploadImage    :(UIImage *) _image :(NSString *) _url : (NSString *) _fileName
{
    
    // Check rights
//    [ OLCheckRights checkRights ];
    
    
    NSData *imageData = UIImageJPEGRepresentation(_image, 90);
    
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
    [request setURL:[NSURL URLWithString:_url]];
    [request setHTTPMethod:@"POST"];
    
    NSString *boundary      = @"---------------------------14737809831466499882746641449";
    NSString *contentType   = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *body     = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary]
                      dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"picture\"; filename=\"%@\"\r\n", _fileName] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n"
                      dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithData:imageData]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary]
                      dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:body];
    
    NSData *returnData  = [NSURLConnection sendSynchronousRequest:request
                                                    returningResponse:nil
                                                                error:nil];
    responseString      = [[NSString alloc] initWithData:returnData
                                                encoding:NSUTF8StringEncoding] ;
    responseReceived    = TRUE;

}


#pragma mark Upload file
- (void) uploadFile     : (NSString *)          _url
                        : (NSString *)          _fileName
                        : (NSString *)          _contentType
                        : (NSString *)          _key
{
    
    // Check rights
//    [ OLCheckRights checkRights ];
    
    NSData *fileData        = [NSData dataWithContentsOfFile:_fileName];
    
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
    [request setURL:[NSURL URLWithString:_url]];
    [request setHTTPMethod:@"POST"];
    
    NSString *boundary      = @"---------------------------14737809831466499882746641449";
    NSString *contentType   = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *body     = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary]
                      dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", _key, _fileName]
                      dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n"
                      dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithData:fileData]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary]
                      dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:body];
    
    NSData  *returnData     = [NSURLConnection sendSynchronousRequest:request
                                                    returningResponse:nil
                                                                error:nil];
    responseString          = [[NSString alloc] initWithData:returnData
                                                    encoding:NSUTF8StringEncoding];
    responseReceived        = TRUE;
    
    /*
    NSData *fileData = [NSData dataWithContentsOfFile:_fileName];
    [self initRequestWithUrl:_url];
    [request setTimeOutSeconds:50];
	[request setData:fileData withFileName:_fileName andContentType:_contentType forKey:_key];
    [request setStringEncoding:NSASCIIStringEncoding];
    if (_isAsynchronous)
         [request startAsynchronous];
    else
        [request startSynchronous];
    */
    
}


#pragma mark Send Post Data
- (void) sendPostData : (NSString *) _url : (NSArray *) _postLabel : (NSArray *) _postValues  : (BOOL) _isAsynchronous
{
    // Check rights
//    [ OLCheckRights checkRights ];
    
    int nbParams            = 0;
    
    responseReceived        = FALSE;
    if (responseString)
        MF_COCOA_RELEASE(responseString);
    responseString          = @"";
    
    // Check post values
    if ( (_postLabel!=nil) && (_postValues!=nil) ) 
    {
        if ( [ _postLabel count ] == [ _postValues count ] ) 
            nbParams = [ _postLabel count ];
        else
        {
            if (DEBUG_OLINTERNET)
                DLog(@"-> [ _postLabel count ] (%i) != [ _postValues count ] (%i)",
                     [ _postLabel count ],
                     [ _postValues count ]);
            
            [[NSNotificationCenter defaultCenter] postNotificationName:OL_INTERNET_NOTIFICATION_ERROR
                                                                object:self];
            return;
        }
    }
    else
    {
        if (DEBUG_OLINTERNET)
            DLog(@"-> (_postLabel==nil) || (_postValues==nil)]");
    }

    NSMutableData *postData = [[NSMutableData alloc] init];

    // Add post values
    for (int i=0;i<nbParams;i++) 
    {
        if (i==0)
        {
            NSString *tmp   = [NSString stringWithFormat:@"%@=", [ _postLabel objectAtIndex:i ]];
            [postData appendData:[tmp dataUsingEncoding:NSASCIIStringEncoding] ] ;
            [postData appendBytes:[[ _postValues objectAtIndex:i ] UTF8String]
                           length:strlen([[ _postValues objectAtIndex:i ] UTF8String])];
        }
        else
        {
            NSString *tmp   = [NSString stringWithFormat:@"&%@=", [ _postLabel objectAtIndex:i ]];
            [postData appendData:[tmp dataUsingEncoding:NSASCIIStringEncoding  ]];
            [postData appendBytes:[[ _postValues objectAtIndex:i ] UTF8String]
                           length:strlen([[ _postValues objectAtIndex:i ] UTF8String])];
     }

    }
    
    if (traceRequests)    // DEBUG
    {
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        [fmt   setDateFormat : @"yyyy-MM-dd HH-mm-ss"];
        [postData writeToFile: [NSHomeDirectory() stringByAppendingPathComponent:
                                [NSString stringWithFormat:@"%@_requestPostData.txt",
                                                            [fmt stringFromDate:[NSDate date]] ]]
                   atomically:NO];
        MF_COCOA_RELEASE(fmt);
    }

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init] ;
    request.cachePolicy     = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    [request        setURL  : [NSURL URLWithString:_url ]];
    [request setHTTPMethod  : @"POST"];
    [request      addValue  : @"application/x-www-form-urlencoded; charset=utf-8"
        forHTTPHeaderField  : @"Content-Type"];

    [request   setHTTPBody  : postData];
    DLog(@"url : %@", _url);

    NSError *error;
    NSData      *returnData = [NSURLConnection sendSynchronousRequest:request
                                                    returningResponse:nil
                                                                error:&error];
    DLog(@"error : %@", (error ? error.description : @"-"));

    MF_COCOA_RELEASE(responseString);
    responseString          = [[NSString alloc] initWithData:returnData
                                                    encoding:NSUTF8StringEncoding];
    
    responseReceived        = TRUE;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OL_INTERNET_NOTIFICATION_SUCCESS
                                                        object:self];
    
    MF_COCOA_RELEASE(request);
    MF_COCOA_RELEASE(postData);
    
}


- (BOOL) sendPostDataJson : (NSString *) _url : (NSDictionary *) _postDict
{
    // Check rights
//    [ OLCheckRights checkRights ];
    BOOL bRetCode           = NO;
    
    responseReceived        = FALSE;
    if (responseString)
        MF_COCOA_RELEASE(responseString);
    responseString          = [@"" retain];
    
    if ( _postDict != nil)
    {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject: _postDict
                                                           options: 0 // NSJSONWritingPrettyPrinted
                                                             error: &error];
  
        if (jsonData)
        {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_url ]
                                                     cachePolicy: NSURLRequestReloadIgnoringCacheData
                                                 timeoutInterval: 60.0];


            [request setHTTPMethod: @"POST"];
            [request      addValue: @"application/json"
                forHTTPHeaderField: @"Content-Type"];

            [request   setHTTPBody: jsonData];
            
            DLog(@"url : %@", _url);

            if (traceRequests)      // DEBUG
            {
                NSDateFormatter *fmt = [[NSDateFormatter alloc]init];
                [fmt setDateFormat:@"yyyy-MM-dd HH-mm-ss"];
                [jsonData writeToFile: [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_requestJsonPostData.txt",[fmt stringFromDate:[NSDate date]] ]] atomically:NO];
                [fmt release];
            }
            
            NSURLResponse   *response;
            
            error                   = nil;
            NSData      *returnData = [NSURLConnection sendSynchronousRequest:request
                                                            returningResponse:&response
                                                                        error:&error];
            
            NSInteger statusCode    = ((NSHTTPURLResponse *)response).statusCode;
            
            MF_COCOA_RELEASE(responseString);
            responseString          = [[NSString alloc] initWithData:returnData
                                                    encoding:NSUTF8StringEncoding];
            responseReceived        = TRUE;
            
            if (statusCode == 200)
            {
                bRetCode = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:OL_INTERNET_NOTIFICATION_SUCCESS
                                                                    object:self];
            }
            else
                [[NSNotificationCenter defaultCenter] postNotificationName:OL_INTERNET_NOTIFICATION_ERROR
                                                                    object:self];
            
            error                   = nil;
            request                 = nil;
        }
        
        jsonData                    = nil;
        error                       = nil;
     }

    return bRetCode;
}

#pragma mark Send Get Data

- (BOOL) sendGetDataJson : (NSString *) _url : (NSDictionary *) _postDict
{
    // Check rights
    //    [ OLCheckRights checkRights ];
    BOOL  bRetCode          = NO;
    
    responseReceived        = FALSE;
    if (responseString)
        MF_COCOA_RELEASE(responseString);
    
    NSError *error;
    
    NSMutableString *wsUrl = [[NSMutableString alloc] initWithString:_url];
    
    if ( _postDict != nil)
    {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject: _postDict
                                                           options: 0 // NSJSONWritingPrettyPrinted
                                                             error: &error];
        NSString *jsonStr = [NSString stringWithUTF8String:[jsonData bytes]];
        [wsUrl appendString:[ NSString stringWithFormat:@"%@%@", _url, jsonStr]];
        if (traceRequests)      // DEBUG
        {
            NSDateFormatter *fmt = [[NSDateFormatter alloc]init];
            [fmt setDateFormat:@"yyyy-MM-dd HH-mm-ss"];
            [jsonData writeToFile: [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_requestJsonGetData.txt",[fmt stringFromDate:[NSDate date]] ]] atomically:NO];
            [fmt release];
        }
        
        jsonData        = nil;
        
    }
    
    
    DLog(@"url : %@", wsUrl);
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:wsUrl ]
                                                           cachePolicy: NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval: 60.0];
    
    
    [request setHTTPMethod: @"GET"];
    
    NSURLResponse   *response;
    
    error                   = nil;
    NSData      *returnData = [NSURLConnection sendSynchronousRequest:request
                                                    returningResponse:&response
                                                                error:&error];
    
    NSInteger statusCode    = ((NSHTTPURLResponse *)response).statusCode;
    
    MF_COCOA_RELEASE(responseString);
    responseString          = [[NSString alloc] initWithData:returnData
                                                    encoding:NSUTF8StringEncoding];
    responseReceived        = TRUE;
    
    if (statusCode == 200)
    {
        bRetCode            = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:OL_INTERNET_NOTIFICATION_SUCCESS
                                                            object:self];
    }
    else
        [[NSNotificationCenter defaultCenter] postNotificationName:OL_INTERNET_NOTIFICATION_ERROR
                                                            object:self];
    
    error                   = nil;
    request                 = nil;
    MF_COCOA_RELEASE(wsUrl);
    
    return bRetCode;
}


#pragma mark - life cycle
- (id) init
{
    self = [super init];
    if (self)
    {
        traceRequests = NO;
    }
    
    return self;
}

- (void) dealloc 
{
    if (responseString)
        MF_COCOA_RELEASE(responseString);
    if (responseError)
        MF_COCOA_RELEASE(responseError);

    [ super dealloc ];
}

@end
