//
//  SynchroViewController.h
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 14/12/12.
//  Copyright (c) 2012 Onatys. All rights reserved.
//

#import "OLSyncFilesV2.h"
#import "OLSyncDatabaseV2.h"
#import <UIKit/UIKit.h>


// Documents
// #define GRdF_SYNC_DOCUMENT_URL                 @"xml/{token}/documents.xml"
#define GRdF_SYNC_DOCUMENT_URL                 @"getGRDFDocumentForUser/xml/{token}"

// #define GRdF_SYNC_CITY_URL                     @"xml/{token}/cities.xml"
#define GRdF_SYNC_CITY_URL                     @"getGRDFCityForUser/xml/{token}/01"

// #define GRdF_SYNC_ZIP_CITY_URL                 @"xml/{token}/zipcode-cityId.xml"
#define GRdF_SYNC_ZIP_CITY_URL                 @"getGRDFZipCodeCityIdForUser/xml/{token}/01"

// #define GRdF_SYNC_NAME3_CITY_URL               @"xml/{token}/prefix3-cityId.xml"
#define GRdF_SYNC_NAME3_CITY_URL               @"getGRDFPrefixCityIdForUser/xml/{token}/?3"
// #define GRdF_SYNC_NAME4_CITY_URL               @"xml/{token}/prefix4-cityId.xml"
#define GRdF_SYNC_NAME4_CITY_URL               @"getGRDFPrefixCityIdForUser/xml/{token}/?4"
// #define GRdF_SYNC_NAME5_CITY_URL               @"xml/{token}/prefix5-cityId.xml"
#define GRdF_SYNC_NAME5_CITY_URL               @"getGRDFPrefixCityIdForUser/xml/{token}/?5"
// #define GRdF_SYNC_NAME6_CITY_URL               @"xml/{token}/prefix6-cityId.xml"
#define GRdF_SYNC_NAME6_CITY_URL               @"getGRDFPrefixCityIdForUser/xml/{token}/?6"
// #define GRdF_SYNC_NAME7_CITY_URL               @"xml/{token}/prefix7-cityId.xml"
#define GRdF_SYNC_NAME7_CITY_URL               @"getGRDFPrefixCityIdForUser/xml/{token}/?7"

// Database timestamps
// #define GRdF_SYNC_DATABASETIMESTAMPS_URL      @"xml/{token}/databaseTimestamp.xml"
#define GRdF_SYNC_DATABASETIMESTAMPS_URL      @"getDatabaseTimestampsForUser/xml/{token}"

// LocalFiles
// #define GRdF_SYNC_FILES_URL                   @"xml/{token}/localFiles.xml"
#define GRdF_SYNC_FILES_URL                   @"getLocalFilesForUser/xml/{token}"


@interface SynchroViewController : UIViewController <NSXMLParserDelegate,
                                                    OLSyncDatabaseDelegateV2,
                                                    OLSyncFilesDelegateV2>
{
}
// class properties
@property (assign, nonatomic) id                    parentController;
@property (retain, nonatomic) IBOutlet UILabel      *lblPercentage;

// user interface components
@property (retain, nonatomic) IBOutlet UILabel      *lblTitle;
@property (retain, nonatomic) IBOutlet UILabel      *lblSyncMessage_1;
@property (retain, nonatomic) IBOutlet UILabel      *lblSyncProcess_1;
@property (retain, nonatomic) IBOutlet UIView       *viewProgressPie;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *actProcessIndicator;
@property (retain, nonatomic) IBOutlet UITextView   *txtviewFiles;

@property (retain, nonatomic) IBOutlet UIButton     *btnCancel;
@property (retain, nonatomic) IBOutlet UIButton     *btnClose;


// public instance methods
+ (void) cleanDatabaseTimestamps;



@end
