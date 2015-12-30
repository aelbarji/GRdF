//
//  SynchroViewController.m
//  SavoirEtReussir
//
//  Created by Jean-Philippe BEAUFILS on 14/12/12.
//  Copyright (c) 2012 Onatys. All rights reserved.
//

#import "AppDelegate.h"
#import "SynchroViewController.h"

// core data entity
#import "GRDFDocument.h"


// constants
#define     kSynchroNumberOfSteps   5
#define     kSyncProgressIncrement  1./5.

// ---------------- SynchroFile start -----------------------------

@interface SynchroFile: NSObject
{

}
@property (retain, nonatomic) NSString  *relativeFilePath;
@property (retain, nonatomic) NSString  *rootId;
@property (retain, nonatomic) NSString  *contentId;
@property (retain, nonatomic) NSString  *contentType;
@property (readwrite)         BOOL      bCreate;

@end

@implementation SynchroFile
@synthesize relativeFilePath    = _relativeFilePath;
@synthesize rootId              = _rootId;
@synthesize contentId           = _contentId;
@synthesize contentType         = _contentType;
@synthesize bCreate             = _bCreate;

#pragma mark - initialization and memory management
-(SynchroFile *) initWithRelativePath:(NSString *)relativeFilePath
{
    self = [super init];
    if (self)
    {
        [self setRelativeFilePath:relativeFilePath];
        [self setContentType:[_relativeFilePath pathExtension]];
        // spit path into root uid - content uid - contentType
        // relative filePath is following schema: thaleos/photos/<rootUID>/<contentUID>.{png/jpg} => <rootUID> is at index 2 and <contentUID> is at index 3
        NSArray *filePathComponents=[[NSArray alloc] initWithArray:[_relativeFilePath pathComponents]];
        [self setRootId:[NSString stringWithString:[filePathComponents objectAtIndex:2]] ];
        [self setContentId:[NSString stringWithString:[[filePathComponents objectAtIndex:3]stringByDeletingPathExtension] ]];
        
        [filePathComponents release];
    }
    return self;
}


-(void) dealloc
{
    self.relativeFilePath   = nil;
    self.rootId             = nil;
    self.contentId          = nil;
    self.contentType        = nil;
    
    [super dealloc];
}


@end

// ----------------------- SynchroFile end -----------------------------



// ------------- SynchroViewController start -------------------------
@interface SynchroViewController () <OLSyncDatabaseDelegateV2,
                                        OLSyncFilesDelegateV2,
                                        UITextFieldDelegate>
{
    
    // ------- database synchronization  -------
    OLSyncDatabaseV2        *_olSyncDBV2;
    //           timestamps: tables to synch
    NSMutableDictionary     *_tablesSyncNeeded;
    //           xml parser for database timestamps xml stream
    NSString                *_currentElementName;     // store current xml node element
    NSMutableString         *_currentElementValue;    // store current xml node value
    NSMutableDictionary     *_lineDict;               // attribute/value pairs found in xml
    NSMutableDictionary     *_lineDictRef;            // attribute/@"" pairs related to entity
    NSMutableArray          *_xmlDataRows;            // array of lineDict = rows to insert
    NSString                *_returnValue;
    
    //           flags
    BOOL                    _bOverallSyncDataProcessSucceed;
    BOOL                    _bDownloadFilesSucceed;
    
    //            integrity management (relationship)
    BOOL                    _bNeedDatabaseSync;
    BOOL                    _bCustomerIntegrityBroken;
    BOOL                    _bProjectIntegrityBroken;
    BOOL                    _bAddressBookIntegrityBroken;
    
    
    // ------ core data management --------------
    NSManagedObjectContext  *_managedObjectContext;
    
    
    // ---------- file synchronization ----------
    OLSyncFilesV2           *_olSyncFilesV2;
    NSMutableArray          *_errFileNames;
    NSMutableArray          *_remainingFileNames;
    
    // --------- user interface -----------------
    //              progress pie layer
    CGRect                  _frameProcess1;
    float                   _progress;
    NSTimer                 *_timer;
    CALayer                 *_customDrawn;
    //              user cancel request
    BOOL                    _bUserRequestCancel;
    NSMutableArray          *_stepInfos;
}

@end

@implementation SynchroViewController
@synthesize parentController    = _parentController;

#pragma mark - user interface
// to handle synchronization canceled upon user request
-(IBAction) cancel
{
    _bUserRequestCancel=YES;
    _btnClose.hidden=NO;
    _btnCancel.hidden=YES;
    
}

-(IBAction) close
{
    DLog(@"close.start");
    
    [_actProcessIndicator stopAnimating];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GRdF_SYNCHRO_CLOSE_NOTIFICATION
                                                        object:nil];
    
    /*
    if (_parentController)
    {
        [_parentController performSelector:NSSelectorFromString(@"closeSynchro") withObject:nil];
    }
    */
    
    DLog(@"close.end");
}



#pragma mark - public instance methods
- (void) clearSelection
{
    _lblSyncMessage_1.text      = @"";
    _lblSyncProcess_1.text      = @"";
    _txtviewFiles.text          = @"";
}




#pragma mark - NS_xmlParserDelegate methods
- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    // NSLog(@"XML Parser : start document");
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    // NSLog(@"XML Parser : end document");
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    _currentElementName = [elementName copy];
    if(_currentElementValue)
    {
        [_currentElementValue release];
        _currentElementValue = nil;
    }
    
    if ([elementName isEqualToString:@"Database"])
    {
        _lineDict = [[NSMutableDictionary alloc] initWithDictionary:_lineDictRef];
    }
    
    
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    // waiting for @"database" entry
    if ([elementName isEqualToString:@"Database"])
    {
        // NSLog(@"xml end entity: line dict: %@", _lineDict);
        [_xmlDataRows addObject:_lineDict];
        
        [_lineDict release];
        _lineDict=nil;
    }
    else // for other element consider only referenced attributes
    {
        if ([_lineDict objectForKey:elementName]!=nil)
        {
            NSString *timeStamp = [[NSString alloc] initWithString:[[_currentElementValue stringByReplacingOccurrencesOfString:@"\n" withString:@""]
                                                                    stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
            [_lineDict setValue:timeStamp forKey:elementName];
            MF_COCOA_RELEASE(timeStamp);
            
            // NSLog(@"line dict: %@", _lineDict);
        }
    }
    
    [_currentElementName release];
    _currentElementName = nil;
    
    
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if(!_currentElementValue)
        _currentElementValue = [[NSMutableString alloc] initWithString:string];
    else
        [_currentElementValue appendString:string];
    // NSLog(@"xml found char: end - %@",_currentElementValue);
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    DLog(@"xml parser error:%@", parseError);
    _returnValue = [NSString stringWithFormat:@"domain: xml, error code:%i - %@",
                    [parseError code],
                    parseError.description];
}


#pragma mark - uitextfield notification
- (BOOL) textFieldShouldBeginEditing:(UITextField *)textField
{
    if ( textField == (UITextField *)_txtviewFiles )
        return NO;
    else
        return YES;
}


#pragma mark - viewController notifications
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
            interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}


#pragma mark - synchronization process
#pragma mark - synchronization launcher
- (void) launchSynchonization
{
    DLog(@"-> start");
    
    // Do sync only one time per hour
    NSDate *currentDate = [NSDate dateWithIntervalSince1970GMT:[[NSDate date] intervalStringSince1970GMT].integerValue];
    NSDate *lastSyncDate = [NSDate dateWithIntervalSince1970GMT:[ [NSUserDefaults standardUserDefaults]
                                                                 stringForKey:kNSUserDefaultsLastSync].integerValue];
    
//    synchronization once a day
    if ([currentDate isSameDay:lastSyncDate])
    {
        [_actProcessIndicator stopAnimating];
        [self close];
        return;
    }

     
    _stepInfos                  = [[NSMutableArray alloc] init] ;
    _bUserRequestCancel         = NO;
    _bCustomerIntegrityBroken   = NO;
    _bProjectIntegrityBroken    = NO;
    _bAddressBookIntegrityBroken= NO;
    _progress                   = 0.1;
    _customDrawn                = [_viewProgressPie.layer retain];
    _customDrawn.name           = @"progressPie";
    _customDrawn.delegate       = self;
    //    _customDrawn.frame=CGRectMake(300., 300., 100., 100.);
    _customDrawn.backgroundColor=[[UIColor clearColor] CGColor];
    _customDrawn.cornerRadius   = 10.;
    _customDrawn.masksToBounds  = YES;
    [self.view.layer addSublayer:_customDrawn];
    [_customDrawn setNeedsDisplay];
    
    [_actProcessIndicator startAnimating];
    usleep(500);
    
    DLog(@"-> stop");
    
    [NSThread detachNewThreadSelector:@selector(synchronizeStartProcess)
                             toTarget:self
                           withObject:nil];
}

#pragma mark - files synchronization
- (void) synchronizeStartProcess
{
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc]init];
    
    _bOverallSyncDataProcessSucceed = YES;

    // Download files to keep in sync with b/o (about.pdf, ...)
    _progress+=kSyncProgressIncrement;
    [self refreshDisplayWithProgress:_progress
                      andDescription:NSLocalizedStringFromTable(@"Sync_DownloadFile",
                                                                @"OMBSSynchroLocalizable",
                                                                @"download file")
                          andMessage:nil];
    
    // clear errors and files list
    if (_errFileNames)
        MF_COCOA_RELEASE(_errFileNames);
    if (_remainingFileNames)
        MF_COCOA_RELEASE(_remainingFileNames);
    
    
    // Download (async)
    [self synchFilesDownload:nil];
    
    [pool drain];
    
}

#pragma mark - main database process
- (void) synchronizeMainProcess
{
    DLog(@"synchronizeMainProcess.start");
    
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc]init];
    
    [_stepInfos removeAllObjects];
    
    // DEBUG purpose 
    BOOL activeSynchro          = TRUE;
    
    /*
    NSString *currentDate = [ OLDateUtils getDateTimeFromDate : @"yyyyMMddHH" : [ OLDateUtils getDateInMillisecondsSince1970 ]];
    NSString *lastSyncDate = [ [NSUserDefaults standardUserDefaults]
                               stringForKey:kNSUserDefaultsLastSync];
    
    NSLog(@"synchronizeMainProcess.currentDate:%@", currentDate);
    NSLog(@"synchronizeMainProcess.lastSyncDate:%@", lastSyncDate);
    
    if ( [ currentDate isEqualToString:lastSyncDate ] )
    {
        activeSynchro = FALSE;
    }
    else
    {
        NSString *currentDate = [ OLDateUtils getDateTimeFromDate : @"yyyyMMddHH" : [ OLDateUtils getDateInMillisecondsSince1970 ]];
        [[NSUserDefaults standardUserDefaults] setValue:currentDate forKey:kNSUserDefaultsLastSync];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    */
    
    if (activeSynchro)
    {
        
        // refresh previous status (download async)
        [self refreshDisplayWithProgress:0
                          andDescription:NSLocalizedStringFromTable(@"Sync_DownloadFile",
                                                                    @"OMBSSynchroLocalizable",
                                                                    @"download file")
                              andMessage:(_bDownloadFilesSucceed ?
                                          nil :
                                          NSLocalizedStringFromTable(@"Sync_DownloadFilesError",
                                                                     @"OMBSSynchroLocalizable",
                                                                     @"files not all synched"))];
        
        // step 2
        // Get tables timestamps
        _progress+=kSyncProgressIncrement;
        [self refreshDisplayWithProgress:_progress
                          andDescription:NSLocalizedStringFromTable(@"Sync_DownloadDbTimestamps",
                                                                    @"OMBSSynchroLocalizable",
                                                                    @"checking database timestamps")
                              andMessage:nil];
        BOOL bTableTimestamps=[self getTablesToSync];
        
        // TEST PURPOSE -> to prevent any sync
        // bTableTimestamps = NO;
        
        if (!bTableTimestamps)
        {
            _bOverallSyncDataProcessSucceed=NO;
            [self refreshDisplayWithProgress:0
                              andDescription:nil
                                  andMessage:NSLocalizedStringFromTable(@"Sync_TimestampsError",
                                                                        @"OMBSSynchroLocalizable",
                                                                        @"database timestamps error")];
        }
        else
        {            
            // Step 3
            //  Reference tables : document
            if (_bUserRequestCancel)
            {
                [_stepInfos addObject:NSLocalizedStringFromTable(@"Sync_Inf_CancelByUser",
                                                                 @"OMBSSynchroLocalizable",
                                                                 @"cancel by user")];
                _bOverallSyncDataProcessSucceed=NO;
                return;
            }
            _progress+=kSyncProgressIncrement;
            [self refreshDisplayWithProgress:_progress
                              andDescription:NSLocalizedStringFromTable(@"Sync_DownloadDocumentTable",
                                                                        @"OMBSSynchroLocalizable",
                                                                        @"synch doc. tables")
                                  andMessage:nil];
            
            BOOL bRefDocumentsProcess       = [self processDocumentTableDataDownload];
            _bOverallSyncDataProcessSucceed =_bOverallSyncDataProcessSucceed &&
                                                bRefDocumentsProcess;
            
            if (!bRefDocumentsProcess)
            {
                [_stepInfos addObject:NSLocalizedStringFromTable(@"Sync_Inf_DocumentsDownload",
                                                                 @"OMBSSynchroLocalizable",
                                                                 @"document download")];
            }
            
            // Step 4
            //  Reference tables : city
            if (_bUserRequestCancel)
            {
                [_stepInfos addObject:NSLocalizedStringFromTable(@"Sync_Inf_CancelByUser",
                                                                 @"OMBSSynchroLocalizable",
                                                                 @"cancel by user")];
                _bOverallSyncDataProcessSucceed=NO;
                return;
            }
            _progress+=kSyncProgressIncrement;
            [self refreshDisplayWithProgress:_progress
                              andDescription:NSLocalizedStringFromTable(@"Sync_DownloadCityTable",
                                                                        @"OMBSSynchroLocalizable",
                                                                        @"synch city tables")
                                  andMessage:nil];
            
            BOOL bRefCitiesProcess       = [self processCityTablesDataDownload];
            _bOverallSyncDataProcessSucceed =_bOverallSyncDataProcessSucceed &&
            bRefCitiesProcess;
            
            if (!bRefCitiesProcess)
            {
                [_stepInfos addObject:NSLocalizedStringFromTable(@"Sync_Inf_CitiesDownload",
                                                                 @"OMBSSynchroLocalizable",
                                                                 @"city download")];
            }

            
        }
        // Write last successfull full sync date
        if (_bOverallSyncDataProcessSucceed)
        {
            NSString *currentDate = [[NSDate date] intervalStringSince1970GMT];
            
            [[NSUserDefaults standardUserDefaults] setValue:currentDate forKey:kNSUserDefaultsFullSync];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        // Synchronization process terminated
        [self refreshDisplayWithProgress:1.
                          andDescription:NSLocalizedStringFromTable(@"Sync_ProcessCompleted",
                                                                    @"OMBSSynchroLocalizable",
                                                                    @"synch completed")
                              andMessage:nil];
        
    }
    
    // display final status and messages according to process final status
    if (_bOverallSyncDataProcessSucceed)
    {
        // store date of last synchro completed
        NSString *currentDate = [[NSDate date] intervalStringSince1970GMT];

        [[NSUserDefaults standardUserDefaults] setValue:currentDate forKey:kNSUserDefaultsLastSync];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        dispatch_async(dispatch_get_main_queue(), ^{

            [self close];
        });
    }
    else   
    {
        [_stepInfos insertObject:NSLocalizedStringFromTable(@"Sync_ProcessAborted",
                                                           @"OMBSSynchroLocalizable",
                                                            @"synch completed") atIndex:0];
        DLog(@"step infos:%@",[_stepInfos componentsJoinedByString:@"\n"] )
        [self refreshDisplayWithProgress:1.
                              andDescription:[_stepInfos componentsJoinedByString:@" - "]
                                  andMessage:nil];
            
        _btnClose.hidden    = NO;
        _btnCancel.hidden   = YES;
    }
    
    usleep(500);
    [pool drain];
    
    DLog(@"synchronizeMainProcess.stop");
}



#pragma mark - database download
// ----------------------   Database synchronisation download processes   ------------------
// --------------------------   document data download process   ---------------------------
- (BOOL) processDocumentTableDataDownload
{
    DLog(@"-> start");
    
    BOOL bDownloadOk=YES;
    
    BOOL bSyncNeededForDocument     = ([_tablesSyncNeeded objectForKey:GRdF_ENTITY_DOCUMENT]        != nil);
    
    
    NSMutableString *message        = [NSMutableString stringWithString:@""];
 
    // step 1 - Category
    if (bSyncNeededForDocument)
    {
        NSMutableArray *tblAttributes=[NSMutableArray arrayWithObjects:
                                            @"DocCityNameFull",
                                            @"DocDescription",
                                            @"DocFileName",
                                            @"DocId",
                                            @"DocReference",
                                            @"DocLatitude",
                                            @"DocLongitude",
                                            @"DocTitle",
                                            nil];
        
        NSString *userToken             = [NSString stringWithString:[GRdFGlobals userToken]];
        NSString *wsURL                 = [NSString stringWithFormat:@"%@/%@",
                                           GRdF_SRV_WS_PREFIX,
                                           [GRdF_SYNC_DOCUMENT_URL stringByReplacingOccurrencesOfString:@"{token}"
                                                                                          withString:userToken]];
        
        DLog(@"wsURL:%@", wsURL);
        
        userToken                       = nil;
        NSURL *urlDocument              = [NSURL URLWithString:wsURL];
        
        NSString *msg = [[self olSyncV2]
                         OLSyncBDDEntity:GRdF_ENTITY_DOCUMENT
                         withAttributes:tblAttributes
                         usingDateFormat:@"yyyy-MM-dd HH:mm:ss"
                         usingDecimalSeparator:@"."
                         withXmlStreamString:urlDocument  ] ;
        if (msg)
        {
            bDownloadOk=NO;
            [message appendString:msg];
            //            [iOMBSMOC rollback];
            
        }
        

        wsURL                           = nil;
        urlDocument                     = nil;
        tblAttributes                   = nil;
    }
    
    
    if (bDownloadOk)
    {
        [self storeTimestampsForEntity:GRdF_ENTITY_DOCUMENT];
    }
    else
        [self refreshDisplayWithProgress:0
                          andDescription:nil
                              andMessage:message];
    
    DLog(@"-> %@  .stop", (bDownloadOk ? @"ok" : @"ko"));
    
    return bDownloadOk;
}


// --------------------------   city data download process   ---------------------------
- (BOOL) processCityTablesDataDownload
{
    DLog(@"-> start");
    
    BOOL bDownloadOk=YES;
    
    BOOL bSyncNeededForCity     = ([_tablesSyncNeeded objectForKey:GRdF_ENTITY_CITY]            != nil);
    BOOL bSyncNeededForZC_CId   = ([_tablesSyncNeeded objectForKey:GRdF_ENTITY_ZIPCODE_CITYID]  != nil);
    
    
    NSMutableString *message        = [NSMutableString stringWithString:@""];
    
    // step 1 - City
    if (bSyncNeededForCity)
    {
        NSMutableArray *tblAttributes=[NSMutableArray arrayWithObjects:
                                       @"CityId",
                                       @"CityDepartment",
                                       @"CityLatitudeDeg",
                                       @"CityLongitudeDeg",
                                       @"CityNameFull",
                                       @"CityNameSimple",
                                       @"CityNameSoundex",
                                       @"CityZipCode",
                                       nil];
        
        NSString *userToken             = [NSString stringWithString:[GRdFGlobals userToken]];
        NSString *wsURL                 = [NSString stringWithFormat:@"%@/%@",
                                           GRdF_SRV_WS_PREFIX,
                                           [GRdF_SYNC_CITY_URL stringByReplacingOccurrencesOfString:@"{token}"
                                                                                             withString:userToken]];
        
        DLog(@"wsURL:%@", wsURL);
        
        userToken                       = nil;
        NSURL *urlDocument              = [NSURL URLWithString:wsURL];
        
        NSString *msg = [[self olSyncV2]
                         OLSyncBDDEntity:GRdF_ENTITY_CITY
                         withAttributes:tblAttributes
                         usingDateFormat:@"yyyy-MM-dd HH:mm:ss"
                         usingDecimalSeparator:@"."
                         withXmlStreamString:urlDocument  ] ;
        if (msg)
        {
            bDownloadOk=NO;
            [message appendString:msg];
            //            [iOMBSMOC rollback];
            
        }
        else
            [self storeTimestampsForEntity:GRdF_ENTITY_CITY];
        
        wsURL                           = nil;
        urlDocument                     = nil;
        tblAttributes                   = nil;
    }
    
    // Step 2 : zipcode-cityId
    if (bSyncNeededForZC_CId)
    {
        NSMutableArray *tblAttributes=[NSMutableArray arrayWithObjects:
                                       @"CityId",
                                       @"CityNameFull",
                                       @"CityZipCode",
                                       nil];
        
        NSString *userToken             = [NSString stringWithString:[GRdFGlobals userToken]];
        NSString *wsURL                 = [NSString stringWithFormat:@"%@/%@",
                                           GRdF_SRV_WS_PREFIX,
                                           [GRdF_SYNC_ZIP_CITY_URL stringByReplacingOccurrencesOfString:@"{token}"
                                                                                         withString:userToken]];
        
        DLog(@"wsURL:%@", wsURL);
        
        userToken                       = nil;
        NSURL *urlDocument              = [NSURL URLWithString:wsURL];
        
        NSString *msg = [[self olSyncV2]
                         OLSyncBDDEntity:GRdF_ENTITY_ZIPCODE_CITYID
                         withAttributes:tblAttributes
                         usingDateFormat:@"yyyy-MM-dd HH:mm:ss"
                         usingDecimalSeparator:@"."
                         withXmlStreamString:urlDocument  ] ;
        if (msg)
        {
            bDownloadOk=NO;
            [message appendString:msg];
            //            [iOMBSMOC rollback];
            
        }
        else
            [self storeTimestampsForEntity:GRdF_ENTITY_ZIPCODE_CITYID];
        
        
        wsURL                           = nil;
        urlDocument                     = nil;
        tblAttributes                   = nil;
    }
    
    // Step 3 : cityName prefix-cityId
    for (NSInteger idx = 3; idx <= 7; idx++)
    {
        NSString *tblName       = @"";
        NSString *wsMainURL     = @"";
        switch (idx)
        {
            case 3:
            {
                tblName         = GRdF_ENTITY_NAME3_CITYID;
                wsMainURL       = GRdF_SYNC_NAME3_CITY_URL;
            } break;
            case 4:
            {
                tblName         = GRdF_ENTITY_NAME4_CITYID;
                wsMainURL       = GRdF_SYNC_NAME4_CITY_URL;
            } break;
            case 5:
            {
                tblName         = GRdF_ENTITY_NAME5_CITYID;
                wsMainURL       = GRdF_SYNC_NAME5_CITY_URL;
            } break;
            case 6:
            {
                tblName         = GRdF_ENTITY_NAME6_CITYID;
                wsMainURL       = GRdF_SYNC_NAME6_CITY_URL;
            } break;
            case 7:
            {
                tblName         = GRdF_ENTITY_NAME7_CITYID;
                wsMainURL       = GRdF_SYNC_NAME7_CITY_URL;
            } break;
                
            default:
                break;
        }
        
        BOOL bSyncNeeded   = ([_tablesSyncNeeded objectForKey:tblName]  != nil);

        if (bSyncNeeded)
        {
            NSMutableArray *tblAttributes=[NSMutableArray arrayWithObjects:
                                           @"CityId",
                                           @"CityNameFull",
                                           @"Prefix",
                                           nil];
            
            NSString *userToken             = [NSString stringWithString:[GRdFGlobals userToken]];
            NSString *wsURL                 = [NSString stringWithFormat:@"%@/%@",
                                               GRdF_SRV_WS_PREFIX,
                                               [wsMainURL stringByReplacingOccurrencesOfString:@"{token}"
                                                                                                 withString:userToken]];
            
            DLog(@"wsURL:%@", wsURL);
            
            userToken                       = nil;
            NSURL *urlDocument              = [NSURL URLWithString:wsURL];
            
            NSString *msg = [[self olSyncV2]
                             OLSyncBDDEntity:tblName
                             withAttributes:tblAttributes
                             usingDateFormat:@"yyyy-MM-dd HH:mm:ss"
                             usingDecimalSeparator:@"."
                             withXmlStreamString:urlDocument  ] ;
            if (msg)
            {
                bDownloadOk=NO;
                [message appendString:msg];
                //            [iOMBSMOC rollback];
                
            }
            else
                [self storeTimestampsForEntity:tblName];
            
            
            
            wsURL                           = nil;
            urlDocument                     = nil;
            tblAttributes                   = nil;
        }
    }

    if (!bDownloadOk)
        [self refreshDisplayWithProgress:0
                          andDescription:nil
                              andMessage:message];
    
    DLog(@"-> %@  .stop", (bDownloadOk ? @"ok" : @"ko"));
    
    return bDownloadOk;
}




// -------------------------  End of data download processes ---------------------------------

// -------------  database timestamps  -------------------
-(BOOL) getTablesToSync
{
    DLog(@"-> start");
    
    BOOL bRetCode       = FALSE;
    
    
    if (_tablesSyncNeeded)
        MF_COCOA_RELEASE(_tablesSyncNeeded);
    
    _tablesSyncNeeded   = [[NSMutableDictionary alloc] init] ;
    _bNeedDatabaseSync  = NO;
    
    // create and retain empty dictionary of attributes (columns) to fill with xml data
    if (_lineDictRef)
        MF_COCOA_RELEASE(_lineDictRef);

    
    // 2014/06 : add translation rule to comply with xml stream
    // build alternate key to match database entity names
    _lineDictRef                    = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                            @"", GRdF_ENTITY_DOCUMENT,
                                       /*
                                            @"", GRdF_ENTITY_CITY,
                                            @"", GRdF_ENTITY_ZIPCODE_CITYID,
                                            @"", GRdF_ENTITY_NAME3_CITYID,
                                            @"", GRdF_ENTITY_NAME4_CITYID,
                                            @"", GRdF_ENTITY_NAME5_CITYID,
                                            @"", GRdF_ENTITY_NAME6_CITYID,
                                            @"", GRdF_ENTITY_NAME7_CITYID,
                                        */
                                            nil ] ;
    
    // --------------------------
    // Phase 1 : XML Parsing
    // --------------------------
    if (_xmlDataRows)
        MF_COCOA_RELEASE(_xmlDataRows);
    
    _xmlDataRows = [[NSMutableArray alloc] init];

    NSString *userToken             = [NSString stringWithString:[GRdFGlobals userToken]];
    NSString *wsURL                 = [NSString stringWithFormat:@"%@/%@",
                                       GRdF_SRV_WS_PREFIX,
                                       [GRdF_SYNC_DATABASETIMESTAMPS_URL stringByReplacingOccurrencesOfString:@"{token}"
                                                                                                 withString:userToken]];
    userToken                       = nil;
    
    DLog(@"timestamps url : %@", wsURL);
    
    NSURL *url                      = [NSURL URLWithString:wsURL];
    NSData *dataStream              = [NSData dataWithContentsOfURL:url];
    NSXMLParser *xmlParser          = [[NSXMLParser alloc] initWithData:dataStream ];
    xmlParser.delegate              = self;
    
    [xmlParser parse];
    
    dataStream          = nil;
    url                 = nil;
    wsURL               = nil;
    MF_COCOA_RELEASE(xmlParser);
    
    if (_returnValue  == nil)
    {
        // --------------------------
        // Phase 2 : compare current values and update need to synchronize tables
        // --------------------------
        for (NSDictionary *dict in _xmlDataRows)  // should have only one row
        {
            // if NSUserDefault table timestamps <> dict timestamp
            DLog(@"dict: %@", dict);
            
            for (id key in dict)
            {
                id object           = [dict objectForKey:key];
                
                NSString *curValue  = [GRdFGlobals getStringUserDefaultValueForKey:key
                                                                withDefaultValue:@""];
                
                DLog(@"id : %@ - New value:'%@' / oldValue:'%@'",
                     key,
                     object,
                     curValue);
                
                if (![object isEqualToString:curValue])
                {
                    _bNeedDatabaseSync = YES;
                    [_tablesSyncNeeded setValue:object
                                         forKey:key];
                }
                
                curValue            = nil;
                object              = nil;
            }
        }

        bRetCode        = TRUE;
        
    }
    
    
    MF_COCOA_RELEASE(_lineDictRef);
    
    DLog(@"-> stop");
    
    return bRetCode;
}



#pragma mark - synchronization sub processes

// Upload database : treat all database events not pushed realtime (local mode)
- (void) synchDatabaseUpload
{
    DLog(@"SyncDatabaseUpload.start");
    usleep(500);
    
    NSAutoreleasePool *pool;
    pool = [[NSAutoreleasePool alloc] init];
    // to allow final HUD to display while loading page
    sleep(1);
    
    
    
    //    bSyncDBPushPerformed=TRUE;
    
    [NSThread detachNewThreadSelector:@selector(synchronizeMainProcess) toTarget:self withObject:nil];
    //    [self performSelectorOnMainThread:@selector(synchronizeMainProcess) withObject:nil waitUntilDone:NO];
    
    [pool drain];
    
    DLog(@"SyncDatabaseUpload.stop");
}



// facility methods

- (NSString *)urlEncodeValue:(NSString *)str
{
    NSCharacterSet *allowedCharacters = [NSCharacterSet URLQueryAllowedCharacterSet];
    NSString *result = [str stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];

 //   NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)str, NULL, CFSTR("!*'\";$,#[] @"), kCFStringEncodingUTF8);
    return [result autorelease];
}




-(void) synchFilesDownload:(id) currentHUD
{
    DLog(@"-> start");
    usleep(500);
    
    _bDownloadFilesSucceed          = FALSE;
    
    // assess application folders exist
    [GRdFGlobals createApplicationFolders];
    
    NSString *userToken             = [NSString stringWithString:[GRdFGlobals userToken]];
    NSString *wsURL                 = [NSString stringWithFormat:@"%@/%@",
                                       GRdF_SRV_WS_PREFIX,
                                       [GRdF_SYNC_FILES_URL stringByReplacingOccurrencesOfString:@"{token}"
                                                                                                 withString:userToken]];
    userToken                       = nil;
    
    DLog(@"files download url : %@", wsURL);

    NSURL *url                      = [NSURL URLWithString:wsURL ];
    
    [[self olSyncFiles] syncLocalFilesFromXMLURL:url];
    
    url                             = nil;
    wsURL                           = nil;
    
    DLog(@"-> stop");
}


#pragma mark - OLSyncFiles delegate notifications
- (void)                OLSyncFiles:(OLSyncFilesV2 *)   controller
                 remainingFileNames:(NSArray *)         fileNames
{
    if (!_remainingFileNames)
    {
        _remainingFileNames = [[NSMutableArray alloc] init];
    }
    
    [_remainingFileNames addObjectsFromArray:fileNames];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        _txtviewFiles.text = [fileNames componentsJoinedByString:@"\n"];
    }];
    
}

- (void)                OLSyncFiles:(OLSyncFilesV2 *)   controller
            errorProcessingFileName:(NSString *)        fileName
{
    if (!_errFileNames)
    {
        _errFileNames = [[NSMutableArray alloc] init];
    }
    
    [_errFileNames addObject:fileName];
}

- (void)                OLSyncFiles: (OLSyncFilesV2 *)  controller
fileSynchronizationDidEndWithStatus: (BOOL)             status
                         andMessage: (NSString *)       message
{
    DLog(@"File download synchronisation ended with message :%@",message);
    _bDownloadFilesSucceed=status;
    _bOverallSyncDataProcessSucceed=_bOverallSyncDataProcessSucceed && status;
    
    NSMutableString *msg = [[NSMutableString alloc] initWithString:@""];
    int nbRemainingFiles = (_remainingFileNames ? [_remainingFileNames count] : 0);
    int nbErrorFiles     = (_errFileNames       ? [_errFileNames count]       : 0);
    
    if (nbRemainingFiles > 0)
    {
        [msg appendFormat:@"%@\n%@\n\n",
         (nbRemainingFiles > 1 ?
          NSLocalizedStringFromTable(@"Sync_DownloadRemainFiles",
                                     @"OMBSSynchroLocalizable",
                                     @""):
          NSLocalizedStringFromTable(@"Sync_DownloadRemainFile",
                                     @"OMBSSynchroLocalizable",
                                     @"")),
         [_remainingFileNames componentsJoinedByString:@"\n"] ];
    }
    if (nbErrorFiles > 0)
    {
        [msg appendFormat:@"%@\n%@",
         (nbErrorFiles > 1 ?
          NSLocalizedStringFromTable(@"Sync_DownloadMissingFiles",
                                     @"OMBSSynchroLocalizable",
                                     @""):
          NSLocalizedStringFromTable(@"Sync_DownloadMissingFile",
                                     @"OMBSSynchroLocalizable",
                                     @"")),
         [_errFileNames componentsJoinedByString:@"\n"] ];
    }
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        _txtviewFiles.text = [NSString stringWithString:msg];
    }];
    
    MF_COCOA_RELEASE(msg);
    
    [NSThread detachNewThreadSelector:@selector(synchronizeMainProcess)
                             toTarget:self
                           withObject:nil];
}

- (void)            OLSyncFiles: (OLSyncFilesV2 *)  controller
           processingFileNumber: (int)              nbrOfFilesProcessed
                           upon: (int)              nbrOfFiles
                   withFileName: (NSString *)       fileName
                     withObject: (id)               object
{

    if (nbrOfFiles > 0 )
    {
        NSString *label = [NSString stringWithFormat:@"%@ (%u/%u %@) -> %@",
                           NSLocalizedStringFromTable(@"Sync_DownloadFile",
                                                      @"OMBSSynchroLocalizable",
                                                      @"download file"),
                           nbrOfFilesProcessed ,
                           nbrOfFiles,
                           NSLocalizedStringFromTable((nbrOfFiles > 1 ?
                                                       @"Sync_Files" :
                                                       @"Sync_File"),
                                                      @"OMBSSynchroLocalizable",
                                                      @"files"),
                           fileName];
        
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            _lblSyncProcess_1.text = label;
        }];
        
    }
    
}

- (void)            OLSyncFiles: (OLSyncFilesV2 *)  controller
         numberOfFilesProcessed: (int)              nbrOfFiles
                           upon: (int)              nbFilesToProcess
                     withObject: (id)               object
{

    if (nbrOfFiles > 0 )
    {
        NSString *label = [NSString stringWithFormat:@"%@ (%u/%u %@)",
                           NSLocalizedStringFromTable(@"Sync_DownloadFile",
                                                      @"OMBSSynchroLocalizable",
                                                      @"download file"),
                           nbrOfFiles ,
                           nbFilesToProcess,
                           NSLocalizedStringFromTable((nbFilesToProcess > 1 ?
                                                       @"Sync_Files" :
                                                       @"Sync_File"),
                                                      @"OMBSSynchroLocalizable",
                                                      @"files")];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            _lblSyncProcess_1.text = label;
        }];
        
    }

}

-(void)             OLSyncFiles: (OLSyncFilesV2 *)  controller
         numberOfFilesToControl: (int)              nbrOfFiles
                     withObject: (id)               object
{
    DLog(@"OLSyncFiles notifications - nbr of files: %u" , nbrOfFiles);
    
    if (nbrOfFiles > 0)
    {
        NSString *label = [NSString stringWithFormat:@"%@ (%u %@)",
                           NSLocalizedStringFromTable(@"Sync_DownloadFile",
                                                      @"OMBSSynchroLocalizable",
                                                      @"download file"),
                           nbrOfFiles ,
                           NSLocalizedStringFromTable((nbrOfFiles > 1 ? @"Sync_Files" : @"Sync_File"),
                                                      @"OMBSSynchroLocalizable",
                                                      @"files")];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            _lblSyncProcess_1.text = label;
        }];
    }
    
}


#pragma mark - private instance methods
- (NSArray *)fetchRecordsFromEntity:(NSString *)                entityName
           withManagedObjectContext:(NSManagedObjectContext *)  moc
{
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                              inManagedObjectContext:moc];
    NSFetchRequest *request     = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    NSError **error             = nil;
    NSMutableArray *results     = [[moc executeFetchRequest:request error:error]
                                   mutableCopy];
    
    [request release];
    return [results autorelease];
}



// user interface management
- (void) refreshDisplayWithProgress:(float)      progress
                     andDescription:(NSString *) description
                         andMessage:(NSString *) message
{
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        if (description)
        {
            _lblSyncProcess_1.text = [ NSString stringWithFormat:@"        %@", description];
        }
        if (message && message.length > 1)
        {
            NSString *msg=[NSString stringWithFormat:@"%@\n%@",
                           message, _lblSyncMessage_1.text];
            _lblSyncMessage_1.text=msg;
        }
        _lblPercentage.text =[NSString stringWithFormat:@"%.0f%%", MIN(progress, 1)*100];
        
        [_customDrawn setNeedsDisplay];
    }];
    
}

// timestamps management
+ (void) cleanDatabaseTimestamps
{
    NSArray *tables=[[NSArray alloc]
                     initWithObjects:
                     GRdF_ENTITY_DOCUMENT,
                     nil ];
    
    for (NSString *entityName in tables)
    {
        [GRdFGlobals setStringUserDefaultValue:@"nope" forKey:entityName];
    }
    
    MF_COCOA_RELEASE(tables);
    
    
}

- (void) storeTimestampsForEntity:(NSString *) entityName
{
    NSString *newTmstamp = [_tablesSyncNeeded objectForKey:entityName];
    if (newTmstamp)
    {
        DLog(@"update table timestamps (%@) for entity %@",newTmstamp, entityName );
        [GRdFGlobals setStringUserDefaultValue:newTmstamp forKey:entityName];
    }

}

// main synchro components initialization
- (NSManagedObjectContext *) managedObjectContext
{
    if (_managedObjectContext)
    {
        if (_managedObjectContext.undoManager)
        {
            [_managedObjectContext setUndoManager:nil];
        }
        MF_COCOA_RELEASE(_managedObjectContext);
    }
    
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    [_managedObjectContext setPersistentStoreCoordinator:[iGRdFMOC persistentStoreCoordinator]];
    
    NSUndoManager *anUndoManager = [[NSUndoManager alloc] init];
    [anUndoManager setLevelsOfUndo:3];
    
    [_managedObjectContext setUndoManager:anUndoManager];
    [anUndoManager release];
    
    return _managedObjectContext;
}


- (OLSyncDatabaseV2 *) olSyncV2
{
    if (!_olSyncDBV2)
    {
        _olSyncDBV2 = [[OLSyncDatabaseV2 alloc] initWithStore:[iGRdFMOC persistentStoreCoordinator]];
        _olSyncDBV2.delegate = self;
    }
    
    return _olSyncDBV2;
}

- (OLSyncFilesV2 *) olSyncFiles
{
    if (!_olSyncFilesV2)
    {
        _olSyncFilesV2 = [[OLSyncFilesV2 alloc] initWithStore: [iGRdFMOC persistentStoreCoordinator]
                                                 andSrvDocRoot: GRdF_SRV_DOCROOT];
        _olSyncFilesV2.delegate = self;
    }
    
    return _olSyncFilesV2;
}

// user interface management
-(void) localize
{
    [_btnCancel setTitle: NSLocalizedString(@"Cancel", @"Cancel")
                forState:UIControlStateNormal];
    [_btnClose  setTitle: NSLocalizedString(@"Continue", @"Continue")
                forState:UIControlStateNormal];
    
    _lblTitle.text      = NSLocalizedStringFromTable(@"Sync_Description",
                                                     @"OMBSSynchroLocalizable",
                                                     @"Synchronization description");
}

// progress pie management
-(void) drawLayer:(CALayer *)layer inContext:(CGContextRef)context

{
    if ([layer.name isEqualToString:@"progressPie"])
    {
        float   width           = layer.bounds.size.width;
        CGFloat circleRadius    = (width / 2) ;
        CGPoint circleCenter    = CGPointMake(CGRectGetMidX(layer.bounds), CGRectGetMidY(layer.bounds));
        
        DLog(@"circleCenter : %f, %f", circleCenter.x, circleCenter.y);
        UIGraphicsPushContext(context);
        
        // step 1 : inactive background alreaydy drawn in imageview behing view layer
        UIImage *img = [UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"bkgProgressPie_inactive" ofType: @"png"]];
        //        [img drawInRect:CGRectMake(0, 0, 300, 300)];  // coordonnées dans le graphic context
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, circleCenter.x, circleCenter.y);
        CGContextAddArc(context, circleCenter.x, circleCenter.y, circleRadius, 0, 2*M_PI, 0);
        CGContextClosePath(context);
        
        CGContextSaveGState(context);
        CGContextSetFillColorWithColor(context, [[UIColor colorWithPatternImage:img] CGColor]);
        CGContextFillPath(context);
        
        CGContextRestoreGState(context);
        
        
        
        // step 2 : reckon angle versus progress
        _progress = MIN(MAX(0.0, _progress), 1.0);
        CGFloat startAngle      = -M_PI_2;
        CGFloat endAngle        = startAngle + (_progress * 2 * M_PI);
        
        
        // step 3 : draw arc centered in layer setting clipping mode
        // set with Even Odd method => in case of non winding zero method, as the 2 arcs are built clockwise, clipping area would have become the entire circle...
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, circleCenter.x, circleCenter.y);
        CGContextAddArc(context,circleCenter.x, circleCenter.y, circleRadius, startAngle, endAngle, 0);
        CGContextClosePath(context);
        
        CGContextSaveGState(context);
        UIImage *img2 = [UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"bkgProgressPie_active" ofType: @"png"]];
        CGContextSetFillColorWithColor(context, [[UIColor colorWithPatternImage:img2] CGColor]);
        CGContextFillPath(context);
        
        CGContextRestoreGState(context);
        
        
        UIGraphicsPopContext();
    }
}


- (void) cleanMemory
{
    DLog(@"-> Begin");
    
    if (_olSyncDBV2)
        MF_COCOA_RELEASE(_olSyncDBV2);
    if (_managedObjectContext)
    {
        [_managedObjectContext setUndoManager:nil];
        MF_COCOA_RELEASE(_managedObjectContext);
    }
    
    if (_olSyncFilesV2)
        MF_COCOA_RELEASE(_olSyncFilesV2);
    if (_errFileNames)
        MF_COCOA_RELEASE(_errFileNames);
    if (_remainingFileNames)
        MF_COCOA_RELEASE(_remainingFileNames);
    
    
    if (_tablesSyncNeeded)
        MF_COCOA_RELEASE(_tablesSyncNeeded);
    
    if (_currentElementName)
        MF_COCOA_RELEASE(_currentElementName);
    if (_currentElementValue)
        MF_COCOA_RELEASE(_currentElementValue);
    if (_lineDict)
        MF_COCOA_RELEASE(_lineDict);
    if (_lineDictRef)
        MF_COCOA_RELEASE(_lineDictRef);
    if (_xmlDataRows)
        MF_COCOA_RELEASE(_xmlDataRows);
    if (_returnValue)
        MF_COCOA_RELEASE(_returnValue);
    
    if (_stepInfos)
        MF_COCOA_RELEASE(_stepInfos);
    
    if (_customDrawn)
        [_customDrawn release];

    _parentController   = nil;
    
    DLog(@"-> End");
}


#pragma mark - initialization
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewDidAppear:(BOOL)animated
{
    _btnClose.hidden=YES;
    [self localize];
    [self launchSynchonization];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _lblSyncProcess_1.layer.cornerRadius = 8;
    _frameProcess1 = _lblSyncProcess_1.frame;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




- (void)dealloc
{
    DLog(@"-> deallocation");
    
    [self cleanMemory];
    
    
    MF_COCOA_RELEASE(_lblTitle);
    MF_COCOA_RELEASE(_lblSyncProcess_1);
    MF_COCOA_RELEASE(_viewProgressPie);
    MF_COCOA_RELEASE(_lblSyncMessage_1);
    MF_COCOA_RELEASE(_btnCancel);
    MF_COCOA_RELEASE(_btnClose);
    MF_COCOA_RELEASE(_lblPercentage);
    MF_COCOA_RELEASE(_actProcessIndicator);
    MF_COCOA_RELEASE(_txtviewFiles);
    
    self.view = nil;
    
    [super dealloc];
}

- (void)viewDidUnload
{
    [self setParentController   :nil];
    [self setLblTitle           :nil];
    [self setLblSyncProcess_1   :nil];
    [self setViewProgressPie    :nil];
    [self setLblSyncMessage_1   :nil];
    [self setBtnCancel          :nil];
    [self setBtnClose           :nil];
    [self setLblPercentage      :nil];
    [self setActProcessIndicator:nil];
    
    [super viewDidUnload];
}
@end
