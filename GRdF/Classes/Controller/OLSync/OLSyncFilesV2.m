//
//  OLSyncFiles.m
//  FileSynchronize
//
//  Created by zhangpanpan on 12-9-17.
//  Copyright (c) 2012年 zhangpanpan. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "OLSyncFilesV2.h"
#import "LocalFiles.h"


@interface OLSyncFilesV2()
{
    NSString                            *_srvDocRoot;
    NSString                            *_localDocRoot;
    
//    FileParserV2                        *_parser;
    NSPersistentStoreCoordinator        *_persistentStore;
    
    NSMutableArray                      *fileArray;
}
@property (retain, nonatomic)   NSString        *srvDocRoot;
@property (retain, nonatomic)   NSString        *localDocRoot;

@property ( nonatomic, retain ) NSMutableArray  *fileArray;

@end

@implementation OLSyncFilesV2
@synthesize fileArray;
@synthesize srvDocRoot              = _srvDocRoot;
@synthesize localDocRoot            = _localDocRoot;
@synthesize object                  = _object;



#pragma mark - public instance methods

// Synchro for download
-(void) syncLocalFilesFromXMLURL:(NSURL *)XMLURL
{
    
    // Step 1 : launch xml parsing
    NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
  
    
    // 201'/06/16 JPh : add autorelease
    FileParserV2 *parser      = [[[FileParserV2 alloc]init] autorelease] ;
    parser.delegate           = self;
    if ([parser.stories count] == 0)
    {
        [parser parseXMLFileURL:XMLURL];
    }
    
    [pool drain];
    
}



- (NSMutableArray*) allLocalFilesInManagedObjectContext:(NSManagedObjectContext *) moc
{
//    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init];
//    [moc setPersistentStoreCoordinator:_persistentStore];

    
    NSEntityDescription  *entity    = [NSEntityDescription entityForName:kSyncLocalFilesEntityName inManagedObjectContext:moc];
    NSFetchRequest       *request   = [[NSFetchRequest alloc]init];
    [request setEntity:entity];
    
    NSSortDescriptor *sortDescriptor= [[NSSortDescriptor alloc]initWithKey:kSyncAttrLocalFileURL ascending:NO];
    NSArray         *sortDescriptors= [NSArray arrayWithObject:sortDescriptor ];
    [request setSortDescriptors:sortDescriptors];
    [sortDescriptor release];
    NSError *error;
    NSMutableArray *mutableFetchResults = [[moc executeFetchRequest:request
                                                              error:&error] mutableCopy];
    
    if (!mutableFetchResults)
    {
        DLog(@"can't fetch local files");
    }
    
    [self setFileArray:mutableFetchResults];
    [mutableFetchResults release];
    [request release];
    
    
//    MF_COCOA_RELEASE(moc);
    
    return fileArray;
}


#pragma mark - static methods
// List localFiles elligible for upload synchro
+ (NSArray *) localFilesToUploadWithStore:(NSPersistentStoreCoordinator *) coordinator
                                forStatus:(NSString *)syncStatus
                         cleanNoFileEntry:(BOOL) bCleanNoFileEntry
{
    // Step 1 : fetch all record in localFiles with status pending upload/download
    // Step 2 : synchro -> will be performed at application level
    BOOL bRetCode                   = TRUE;

    if (!coordinator )
        return nil;
    
    NSManagedObjectContext *moc     = [[NSManagedObjectContext alloc] init];
    [moc setPersistentStoreCoordinator:coordinator];
    NSUndoManager *anUndoManager    = [[NSUndoManager alloc] init];
    [anUndoManager setLevelsOfUndo  : 3];
    [moc            setUndoManager  : anUndoManager];
    [anUndoManager release];
    
    NSEntityDescription  *entity    = [NSEntityDescription entityForName:kSyncLocalFilesEntityName
                                               inManagedObjectContext:moc];
    NSFetchRequest       *request   = [[NSFetchRequest alloc]init];
    [request setEntity:entity];
    
    NSSortDescriptor *sortDescriptor= [[NSSortDescriptor alloc] initWithKey:kSyncAttrLocalFileURL
                                                                     ascending:NO];
    NSArray    *sortDescriptors     = [NSArray arrayWithObject:sortDescriptor ];
    [request    setSortDescriptors  : sortDescriptors];
    [sortDescriptor release];
    
    NSError *error;
    NSArray *fetchResults           = [[moc executeFetchRequest:request
                                                          error:&error] mutableCopy];
    if (!fetchResults)
    {
        DLog(@"can't fetch local files");
        bRetCode= FALSE;
    }
    
    if (bRetCode)
    {
        NSPredicate *predicate      = [NSPredicate predicateWithFormat:@"%K == %@",
                                                            kSyncAttrLocalFileStatus,
                                                            syncStatus];
//                                       [NSString stringWithFormat:@"%@ like '%@*'",
//                                                                   kSyncAttrLocalFileStatus,
//                                                                   syncStatus]];
        
        NSArray *localFiles         = [[fetchResults filteredArrayUsingPredicate:predicate] copy ];
        
        MF_COCOA_RELEASE(fetchResults);
        MF_COCOA_RELEASE(request);
        
        NSMutableArray *filesToUpload=[[NSMutableArray alloc]init];
        for (LocalFiles *file in localFiles)
        {
            NSString *relFilePath   = file.localFileURL;
            if (relFilePath && relFilePath.length > 1)
            {
                NSString *filePath  = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                            NSUserDomainMask,
                                                                            YES)
                                         lastObject]
                                        stringByAppendingPathComponent:relFilePath] ;
                
                if ( [[NSFileManager defaultManager] fileExistsAtPath:filePath] )
                {
                    [filesToUpload addObject:[file localFileURL]];
                }
                else
                    if (bCleanNoFileEntry)
                    {
                        [moc deleteObject:file];
//                      if (![moc save:nil])
//                          [moc rollback];
                    }
                
                filePath            = nil;
            }
            else if (bCleanNoFileEntry)
            {
                [moc deleteObject:file];
//                if (![moc save:nil])
//                    [moc rollback];
            }
        }
        
        if (![moc       save    : nil])
            [moc rollback];
        
        [moc    setUndoManager  : nil];
        MF_COCOA_RELEASE(moc);
        
        NSArray *results        = [NSArray arrayWithArray:filesToUpload];
        MF_COCOA_RELEASE(filesToUpload);
        MF_COCOA_RELEASE(localFiles);
        
        return results ;
    }
    else
    {
        MF_COCOA_RELEASE(fetchResults);
        MF_COCOA_RELEASE(request);
    
        [moc setUndoManager : nil];
        MF_COCOA_RELEASE(moc);
        
        return nil;
    }
}

+ (NSString *)md5StringFromRelativeFileWithPath:(NSString *)relativeFilePath
{
    NSString *filePath=[[[NSString alloc] initWithString:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:relativeFilePath]] autorelease];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        return [OLSyncFilesV2
                md5StringFromData:[NSData dataWithContentsOfFile:filePath]];
    }
    else
        return @"";
    

}

+ (NSString *)md5StringFromData:(NSData *)data
{
    void *cData = malloc([data length]);
    unsigned char resultCString[16];
    [data getBytes:cData length:[data length]];
    
    CC_MD5(cData, [data length], resultCString);
    free(cData);
    
    NSString *result = [NSString stringWithFormat:
                        @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                        resultCString[0], resultCString[1], resultCString[2], resultCString[3],
                        resultCString[4], resultCString[5], resultCString[6], resultCString[7],
                        resultCString[8], resultCString[9], resultCString[10], resultCString[11],
                        resultCString[12], resultCString[13], resultCString[14], resultCString[15]
                        ];
    return result;
}

+ (BOOL) localFileIsSynchedForRelativeFilePath:(NSString *)                     relativeFilePath
                                     withStore:(NSPersistentStoreCoordinator *) coordinator
{
    BOOL bRetCode = YES;
    
    if (!coordinator )
        return NO;
    
    NSManagedObjectContext *moc  = [[NSManagedObjectContext alloc] init];
    [moc setPersistentStoreCoordinator:coordinator];

    NSEntityDescription  *entity = [NSEntityDescription entityForName:kSyncLocalFilesEntityName
                                               inManagedObjectContext:moc];
    NSFetchRequest      *request = [[NSFetchRequest alloc]init];
    [request            setEntity: entity];
    
    NSSortDescriptor *sortDesc   = [[NSSortDescriptor alloc]initWithKey:kSyncAttrLocalFileURL
                                                              ascending:NO];
    NSArray  *sortDescriptors    = [NSArray arrayWithObject:sortDesc ];
    [request setSortDescriptors  : sortDescriptors];
    [sortDesc release];
    
    NSError *error;
    NSArray *results             = [[moc executeFetchRequest:request
                                                       error:&error] mutableCopy];
    if (!results)
    {
        DLog(@"can't fetch local files");
        bRetCode                 = NO;
    }
    
    if (bRetCode)
    {
        NSPredicate *predicate   = [NSPredicate predicateWithFormat:@"%K like[cd] %@",
                                                                   kSyncAttrLocalFileURL,
                                                                   relativeFilePath];
        LocalFiles  *currentLocalFile=nil;
        
        NSArray *localFiles      = [results filteredArrayUsingPredicate:predicate];
        if (localFiles.count)
        {
            currentLocalFile     = [localFiles objectAtIndex:0];
            
            bRetCode             = [currentLocalFile.localFileStatus
                                    isEqualToString:kSyncStatusTransmited] ||
                                   [currentLocalFile.localFileStatus
                                    isEqualToString:kSyncStatusReceived];
        }
        
    }
    
    [results release];
    [request release];
    
    MF_COCOA_RELEASE(moc);
    
    return bRetCode;
}

+ (BOOL) logLocalFileChangeWithStore:(NSPersistentStoreCoordinator *) coordinator
                 forRelativeFilePath:(NSString *) relativeFilePath
                           andStatus:(NSString *) aStatus
                       andUpdateDate:(NSString *) fileLastUpdate
{
    BOOL bRetCode=TRUE;
    
    if (!coordinator )
        return NO;
    
    NSManagedObjectContext *moc     = [[NSManagedObjectContext alloc] init];
    [moc setPersistentStoreCoordinator:coordinator];
    NSUndoManager *anUndoManager    = [[NSUndoManager alloc] init];
    [anUndoManager  setLevelsOfUndo : 3];
    [moc            setUndoManager  : anUndoManager];
    [anUndoManager release];
    
    NSEntityDescription  *entity    = [NSEntityDescription entityForName:kSyncLocalFilesEntityName
                                               inManagedObjectContext:moc];
    NSFetchRequest       *request   = [[NSFetchRequest alloc]init];
    [request setEntity:entity];
    
    NSSortDescriptor *sortDescriptor= [[NSSortDescriptor alloc]initWithKey:kSyncAttrLocalFileURL ascending:NO];
    NSArray         *sortDescriptors= [NSArray arrayWithObject:sortDescriptor ];
    [request    setSortDescriptors  : sortDescriptors];
    [sortDescriptor release];
    
    NSError *error;
    NSArray *results                = [[moc executeFetchRequest:request
                                                          error:&error] mutableCopy];
    if (!results) {
        DLog(@"can't fetch local files");
        bRetCode                    = FALSE;
    }
    
    if (bRetCode)
    {
//        NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%@ like '%@*'",kSyncAttrLocalFileURL, relativeFilePath]];

        NSPredicate *predicate      = [NSPredicate predicateWithFormat:@"%K = %@",
                                        kSyncAttrLocalFileURL,
                                        relativeFilePath];
        LocalFiles *currentLocalFile= nil;

        NSArray *localFiles         = [results filteredArrayUsingPredicate:predicate];
        if (localFiles.count)
        { //Update current entry
            currentLocalFile        = [localFiles objectAtIndex:0];
        }
        else
        {  // new entry
            currentLocalFile        = (LocalFiles *) [ NSEntityDescription
                                                      insertNewObjectForEntityForName :kSyncLocalFilesEntityName
                                                               inManagedObjectContext : moc ] ;
        }
        
        [currentLocalFile setLocalFileURL:relativeFilePath];
        [currentLocalFile setLocalFileStatus:aStatus];
        [currentLocalFile setLocalFileLastUpdate:fileLastUpdate];
        [currentLocalFile setLocalFileCRC:[OLSyncFilesV2 md5StringFromRelativeFileWithPath:relativeFilePath]];
        
        bRetCode=([moc save:&error]);
        if (!bRetCode)
        {
            DLog(@"sync local files : failed to log file entry - error:%i %@",
                 error.code,
                 error.debugDescription);
            [moc rollback];
        }
    }
    
    [results release];
    [request release];
    
    [moc setUndoManager:nil];
    MF_COCOA_RELEASE(moc);
    
    return bRetCode;
}

+ (BOOL) logLocalFileChangeWithStore:(NSPersistentStoreCoordinator *) coordinator
                forRelativeFilePath:(NSString *) relativeFilePath
                        forCreation:(BOOL) bCreate
                      andUpdateDate:(NSString *) fileLastUpdate
{
    BOOL bRetCode=TRUE;
    
    if (!coordinator )
        return NO;
    
    NSManagedObjectContext *moc     = [[NSManagedObjectContext alloc] init];
    [moc setPersistentStoreCoordinator:coordinator];
    NSUndoManager *anUndoManager    = [[NSUndoManager alloc] init];
    [anUndoManager setLevelsOfUndo  : 3];
    [moc            setUndoManager  : anUndoManager];
    [anUndoManager release];
    
    NSEntityDescription  *entity    = [NSEntityDescription entityForName:kSyncLocalFilesEntityName
                                               inManagedObjectContext:moc];
    NSFetchRequest       *request   = [[NSFetchRequest alloc]init];
    [request setEntity:entity];
    
    NSSortDescriptor *sortDescriptor= [[NSSortDescriptor alloc]initWithKey:kSyncAttrLocalFileURL ascending:NO];
    NSArray         *sortDescriptors= [NSArray arrayWithObject:sortDescriptor ];
    [request    setSortDescriptors  : sortDescriptors];
    [sortDescriptor release];
    
    NSError *error;
    NSArray *results                = [[moc executeFetchRequest:request
                                                          error:&error] mutableCopy];
    if (!results) {
        DLog(@"can't fetch local files");
        bRetCode                    = FALSE;
    }
 
    if (bRetCode)
    {
//        NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%@ like '%@*'",kSyncAttrLocalFileURL, relativeFilePath]];
        
        NSPredicate *predicate      = [NSPredicate predicateWithFormat:@"%K = %@",
                                       kSyncAttrLocalFileURL,
                                       relativeFilePath];
        LocalFiles *currentLocalFile= nil;
        
        NSArray *localFiles         = [results filteredArrayUsingPredicate:predicate];
        if (localFiles.count)
        { //Update current entry
            currentLocalFile        = [localFiles objectAtIndex:0];
        }
        else
        {  // new entry
            currentLocalFile        = (LocalFiles *) [ NSEntityDescription
                                                      insertNewObjectForEntityForName : kSyncLocalFilesEntityName
                                                               inManagedObjectContext : moc ] ;
        }

        [currentLocalFile setLocalFileURL:relativeFilePath];
        [currentLocalFile setLocalFileStatus:(bCreate?kSyncStatusPendingUploadCreate:kSyncStatusPendingUploadUpdate)];
        [currentLocalFile setLocalFileLastUpdate:fileLastUpdate];
        [currentLocalFile setLocalFileCRC:[OLSyncFilesV2 md5StringFromRelativeFileWithPath:relativeFilePath]];
    
        bRetCode                    = ([moc save:&error]);
        if (!bRetCode)
        {
            DLog(@"sync local files : failed to log file entry - error:%i %@",
                 error.code,
                 error.debugDescription);
            [moc rollback];
        }
    }
    
    [results release];
    [request release];
    
    [moc setUndoManager:nil];
    MF_COCOA_RELEASE(moc);
    
    return bRetCode;
}


+ (BOOL) truncateLocalFileWithStore:(NSPersistentStoreCoordinator *) coordinator
{
    BOOL bRetCode=TRUE;
    
    if (!coordinator )
        return NO;
    
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init];
    [moc setPersistentStoreCoordinator:coordinator];
    NSUndoManager *anUndoManager = [[NSUndoManager alloc] init];
    [anUndoManager setLevelsOfUndo:3];
    [moc setUndoManager:anUndoManager];
    [anUndoManager release];
    
    NSEntityDescription  *entity = [NSEntityDescription entityForName:kSyncLocalFilesEntityName
                                               inManagedObjectContext:moc];
    NSFetchRequest       *request= [[NSFetchRequest alloc]init];
    [request setEntity:entity];
    
    NSSortDescriptor     *sortDescriptor=[[NSSortDescriptor alloc]initWithKey:kSyncAttrLocalFileURL ascending:NO];
    NSArray              *sortDescriptors=[NSArray arrayWithObject:sortDescriptor ];
    [request setSortDescriptors:sortDescriptors];
    [sortDescriptor release];
    
    NSError *error;
    NSArray *results = [[moc executeFetchRequest:request error:&error]mutableCopy];
    if (!results) {
        DLog(@"can't fetch local files");
        bRetCode= FALSE;
    }
    else
    {
        for (LocalFiles *file in results)
        {
            [moc deleteObject:file];
        }
        bRetCode=([moc save:&error]);
        if (!bRetCode)
        {
            DLog(@"sync local files : failed to truncate localFiles - error:%i %@", error.code, error.debugDescription);
            [moc rollback];
        }
        
    }
    
    [results release];
    [request release];
    
    [moc setUndoManager:nil];
    MF_COCOA_RELEASE(moc);
    
    return bRetCode;

}

+ (BOOL) deleteLocalFileEntryWithStore:(NSPersistentStoreCoordinator *) coordinator
                   forRelativeFilePath:(NSString *) relativeFilePath
{
    BOOL bRetCode=TRUE;
    
    if (!coordinator )
        return NO;
    
    NSManagedObjectContext *moc     = [[NSManagedObjectContext alloc] init];
    [moc setPersistentStoreCoordinator:coordinator];
    NSUndoManager *anUndoManager    = [[NSUndoManager alloc] init];
    [anUndoManager setLevelsOfUndo  : 3];
    [moc            setUndoManager  : anUndoManager];
    [anUndoManager release];
    
    NSEntityDescription  *entity    = [NSEntityDescription entityForName:kSyncLocalFilesEntityName
                                               inManagedObjectContext:moc];
    NSFetchRequest       *request   = [[NSFetchRequest alloc]init];
    [request setEntity:entity];
    
    NSSortDescriptor *sortDescriptor= [[NSSortDescriptor alloc]initWithKey:kSyncAttrLocalFileURL ascending:NO];
    NSArray         *sortDescriptors= [NSArray arrayWithObject:sortDescriptor ];
    [request    setSortDescriptors  : sortDescriptors];
    [sortDescriptor release];
    
    NSError *error;
    NSArray *results                = [[moc executeFetchRequest:request
                                                          error:&error] mutableCopy];
    if (!results)
    {
        DLog(@"can't fetch local files");
        bRetCode                    = FALSE;
    }
    
    if (bRetCode)
    {
//        NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%@ like[cd] '%@*'",kSyncAttrLocalFileURL, relativeFilePath]];
        
        NSPredicate *predicate      = [NSPredicate predicateWithFormat:@"%K = %@",
                                       kSyncAttrLocalFileURL,
                                       relativeFilePath];
        
        NSArray *localFiles         = [results filteredArrayUsingPredicate:predicate];
        if (localFiles.count)
        {
            [moc        deleteObject: [localFiles objectAtIndex:0]];
            bRetCode                = ([moc save:&error]);
            if (!bRetCode)
            {
                DLog(@"sync local files : failed to log file entry - error:%i %@",
                     error.code,
                     error.debugDescription);
                [moc rollback];
            }
        }
        

   }
    
    [results release];
    [request release];
    
    [moc setUndoManager:nil];
    MF_COCOA_RELEASE(moc);
    
    return bRetCode;
}


+ (BOOL) toggleLocalFileStatusWithStore:(NSPersistentStoreCoordinator *) coordinator
                    forRelativeFilePath:(NSString *) relativeFilePath
{
    BOOL bRetCode=TRUE;
    
    if (!coordinator )
        return NO;
    
    NSManagedObjectContext *moc     = [[NSManagedObjectContext alloc] init];
    [moc setPersistentStoreCoordinator:coordinator];
    NSUndoManager *anUndoManager    = [[NSUndoManager alloc] init];
    [anUndoManager setLevelsOfUndo  : 3];
    [moc            setUndoManager  : anUndoManager];
    [anUndoManager release];
    
    NSEntityDescription  *entity    = [NSEntityDescription entityForName:kSyncLocalFilesEntityName
                                               inManagedObjectContext:moc];
    NSFetchRequest       *request   = [[NSFetchRequest alloc]init];
    [request setEntity:entity];
    
    NSSortDescriptor *sortDescriptor= [[NSSortDescriptor alloc]initWithKey:kSyncAttrLocalFileURL ascending:NO];
    NSArray         *sortDescriptors= [NSArray arrayWithObject:sortDescriptor ];
    [request    setSortDescriptors  : sortDescriptors];
    [sortDescriptor release];
    
    NSError *error;
    NSArray *results                = [[moc executeFetchRequest:request
                                                          error:&error] mutableCopy];
    if (!results)
    {
        DLog(@"can't fetch local files");
        bRetCode                    = FALSE;
    }
    
    if (bRetCode)
    {
//        NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%@ like[cd] '%@*'",kSyncAttrLocalFileURL, relativeFilePath]];
        NSPredicate *predicate      = [NSPredicate predicateWithFormat:@"%K = %@",
                                       kSyncAttrLocalFileURL,
                                       relativeFilePath];
        LocalFiles  *currentLocalFile=nil;
        
        NSArray *localFiles         = [results filteredArrayUsingPredicate:predicate];
        if (localFiles.count)
        { //Update current entry
            currentLocalFile        = [localFiles objectAtIndex:0];
            
            [currentLocalFile setLocalFileStatus:(([currentLocalFile.localFileStatus isEqualToString:kSyncStatusPendingUploadCreate] ||
                                                   [currentLocalFile.localFileStatus isEqualToString:kSyncStatusPendingUploadUpdate])  ?
                                                  kSyncStatusTransmited :
                                                  ([currentLocalFile.localFileStatus isEqualToString:kSyncStatusPendingDownload] ?
                                                   kSyncStatusReceived :
                                                   currentLocalFile.localFileStatus))];
            [currentLocalFile setLocalFileCRC:[OLSyncFilesV2 md5StringFromRelativeFileWithPath:relativeFilePath]];
            
            bRetCode                = ([moc save:&error]);
            if (!bRetCode)
            {
                DLog(@"sync local files : failed to toggle status file entry - error:%i %@", error.code, error.debugDescription);
                [moc rollback];
            }
        }

    }

    [results release];
    [request release];
    
    [moc setUndoManager:nil];
    MF_COCOA_RELEASE(moc);
    
    return bRetCode;

}


#pragma mark - private instance methods

-(BOOL) saveFileWithFilePath:(NSString *) filePath
               andSrvDocRoot:(NSString *) srvDocRoot
{
    DLog(@"filePath is %@\nsrvDocRoot is %@",filePath, srvDocRoot);
   
    BOOL bRetCode               = TRUE;
    NSString *localFullFilePath = [_localDocRoot
                                    stringByAppendingPathComponent:filePath] ;
    NSData *urlData             = [[[NSData alloc] initWithContentsOfURL:
                                    [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",
                                                          srvDocRoot,
                                                          filePath] ]] autorelease];
    
    NSString *localFileDir      = [localFullFilePath stringByDeletingLastPathComponent]  ;
    
    // check folder exists
    if (![[NSFileManager defaultManager] fileExistsAtPath:localFileDir])
       bRetCode                 = [[NSFileManager defaultManager] createDirectoryAtPath:localFileDir
                                                           withIntermediateDirectories:YES
                                                                            attributes:nil
                                                                                 error:nil];

    if (bRetCode)
        bRetCode                = [urlData writeToFile:localFullFilePath
                                            atomically:FALSE]; // -> FALSE -> overwrite existing file

    
    return bRetCode;
}


- (void) downloadFileMainProcess:(NSArray *) stories
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    
    NSManagedObjectContext *moc     = [[NSManagedObjectContext alloc] init] ;
    [moc setPersistentStoreCoordinator:_persistentStore];
    
    NSUndoManager *anUndoManager    = [[NSUndoManager alloc] init];
    [anUndoManager setLevelsOfUndo  : 3];
    
    [moc            setUndoManager  : anUndoManager];
    [anUndoManager release];
    
    BOOL bGlobalSyncProcessRetCode  = TRUE;
    int  nbFilesToProcess           = stories.count;
    
    // send nb of files to control back to delegate
    [_delegate          OLSyncFiles : self
             numberOfFilesToControl :nbFilesToProcess
                         withObject :_object];
    
    [NSThread sleepForTimeInterval   :0.1];
    
    // load localFiles db
    NSArray     *allLocalFiles      = [NSArray arrayWithArray:[self allLocalFilesInManagedObjectContext:moc]];
    LocalFiles  *currentLocalFile   = nil;
    BOOL        bFile2Download      = FALSE;
    
    // for all items in xml (nsdict)
    int         processedFiles      = 0;
    
    // build list of files to download
    NSMutableArray *remaingingFiles = [[NSMutableArray alloc] init];
    for (NSDictionary *file2download in stories)
    {
        NSString *fileName          = [[NSString alloc]
                                       initWithString:[[file2download valueForKey:kSyncXMLNodeFileURL]
                                              stringByReplacingOccurrencesOfString:@"\n"
                                              withString:@""]] ;
        [remaingingFiles addObject  : [fileName lastPathComponent]];
        MF_COCOA_RELEASE(fileName);
    }
    
    // send delegate list of remaining files
    [_delegate          OLSyncFiles : self
                 remainingFileNames :[NSArray arrayWithArray:remaingingFiles]];
    [NSThread sleepForTimeInterval  : 0.1];
    
    for (NSDictionary *file2download in stories)
    {
        bFile2Download              = FALSE;
        processedFiles             +=1;
        
        bFile2Download              = bFile2Download;   // to prevent warning in analyze
        
        //   --- assess whether file needs to be downloaded
        //      lookup in localFiles db
        NSString *fileName          = [[NSString alloc ] initWithString:
                                       [[file2download valueForKey:kSyncXMLNodeFileURL]
                                            stringByReplacingOccurrencesOfString:@"\n"
                                            withString:@""]] ;
        
        
        // send nb of processed files to delegate
        [_delegate      OLSyncFiles : self
               processingFileNumber : processedFiles
                               upon : nbFilesToProcess
                       withFileName : [ fileName lastPathComponent ]
                         withObject : _object];
        // [NSThread sleepForTimeInterval:0.1];
        
//        NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"localFileURL LIKE[c] '%@'",
//                                                                   [file2download valueForKey:kSyncXMLNodeFileURL ]]];
        
        NSPredicate *predicate      = [NSPredicate predicateWithFormat:@"%K LIKE[c] %@",
                                       kSyncAttrLocalFileURL,
                                       [file2download valueForKey:kSyncXMLNodeFileURL ]];
        
        NSArray *localFiles         = [allLocalFiles filteredArrayUsingPredicate:predicate];
        // DLog(@"file2download : %@", file2download);
        if (localFiles.count)
        {
            //  if entry found (currentEntry = entry)
            currentLocalFile        = [localFiles objectAtIndex:0];
            
            //      if entry.status=pending transmission
            if ([currentLocalFile.localFileStatus isEqualToString:kSyncStatusPendingDownload])
                bFile2Download      = TRUE;
            else
                // check if entry.status = pending upload (the good release of file is not on server)
                if ([currentLocalFile.localFileStatus isEqualToString:kSyncStatusPendingUploadCreate] ||
                    [currentLocalFile.localFileStatus isEqualToString:kSyncStatusPendingUploadUpdate] )
                    bFile2Download  = FALSE;
                else
                    // check entry.CRC differs from item.CRC
                    // DLog(@"current file: %@", currentLocalFile);
                    bFile2Download  =![currentLocalFile.localFileCRC
                                       isEqualToString:[file2download valueForKey:kSyncXMLNodeFileCRC] ];
        }
        else
        {
            //      else  (currentEntry = new entry)
            //          bFile2Download = addEntry in localFileDb  (status : pending transmission)
            //          bGlobalSyncProcessRetCode=bGlobalSyncProcessRetCode & bFile2Download
            currentLocalFile = (LocalFiles *) [ NSEntityDescription insertNewObjectForEntityForName :kSyncLocalFilesEntityName
                                                                             inManagedObjectContext : moc ] ;
            [currentLocalFile setLocalFileCRC:[file2download valueForKey:kSyncXMLNodeFileCRC]];
            [currentLocalFile setLocalFileLastUpdate:[file2download valueForKey:kSyncXMLNodeLastUpdate]];
            //                [currentLocalFile setLocalFileURL:[file2download valueForKey:kSyncXMLNodeFileURL]];
            [currentLocalFile setLocalFileURL:fileName];
            [currentLocalFile setLocalFileStatus:kSyncStatusPendingDownload];
            
            NSError  *error;
            bFile2Download          = ([moc save:&error]);
            if (!bFile2Download)
            {
                DLog(@"sync local files : failed to insert new entry - error:%i %@",
                     error.code, error.debugDescription);
            }
            
        }
        //  --- treat download
        if (bFile2Download)
        {
            // save new file (overwriting) including check local folder existance with automatic creation
            if ([self saveFileWithFilePath:fileName andSrvDocRoot:_srvDocRoot])
            {
                [currentLocalFile setLocalFileStatus:kSyncStatusReceived];
                [currentLocalFile setLocalFileCRC:[file2download valueForKey:kSyncXMLNodeFileCRC]];
                [currentLocalFile setLocalFileLastUpdate:[file2download valueForKey:kSyncXMLNodeLastUpdate]];
                NSError  *error;
                if (![moc save:&error])
                {
                    bGlobalSyncProcessRetCode = FALSE;
                    DLog(@"sync local files : failed to update entry status for filename: %@\n - error:%i %@",
                         [file2download valueForKey:kSyncXMLNodeFileURL],
                         error.code,
                         error.debugDescription);
                    
                    [moc rollback];
                }
            }
            else
            {
                // send notification
                [_delegate      OLSyncFiles : self
                    errorProcessingFileName : [fileName lastPathComponent]];
//                [NSThread sleepForTimeInterval:0.1];
                bGlobalSyncProcessRetCode   = FALSE;
            }
            
        }
        
        // refresh files remaining list and send it to delegate
        int index = [remaingingFiles indexOfObject:[fileName lastPathComponent]];
        if (index != NSNotFound)
        {
            [remaingingFiles removeObjectAtIndex:index];
//            [_delegate OLSyncFiles:self
//                remainingFileNames:[NSArray arrayWithArray:remaingingFiles]];
//            [NSThread sleepForTimeInterval:0.1];
        }
        
        [fileName release];
        
        // send nb of processed files to delegate
//        [_delegate OLSyncFiles:self
//        numberOfFilesProcessed:processedFiles
//                          upon:nbFilesToProcess
//                    withObject:_object];
//        [NSThread sleepForTimeInterval:0.1];
    }
    
    MF_COCOA_RELEASE(remaingingFiles);


    // notify delegate synchro process ended
    [_delegate OLSyncFiles:self fileSynchronizationDidEndWithStatus:bGlobalSyncProcessRetCode
                andMessage:nil];
    [NSThread sleepForTimeInterval:0.1];

    [moc setUndoManager:nil];
    MF_COCOA_RELEASE(moc);
    
    
    
    [pool drain];
    
}

#pragma mark - FileEventParser delegate
- (void)                        FileParser:(FileParserV2 *) aParser
  xmlParserdidFinishParsingWithReturnValue:(NSString *)     returnValue
{
 if (!returnValue)
 {
     [NSThread detachNewThreadSelector:@selector(downloadFileMainProcess:)
                              toTarget:self
                            withObject:aParser.stories];
 }
 else
 {
     // to prevent receiving several errors (sometimes 2 notifications)
     aParser.delegate = nil;
     dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate OLSyncFiles:self fileSynchronizationDidEndWithStatus:FALSE
                    andMessage:returnValue];
    });
 }
}



#pragma mark - initialization
- (id) initWithStore:(NSPersistentStoreCoordinator *)   coordinator
       andSrvDocRoot:(NSString *)                       srvDocRoot
{
    self = [super init];
    if (self) {
        if (coordinator != nil)
        {
            _persistentStore =  coordinator;
        }
        
        [self setSrvDocRoot:(srvDocRoot ? srvDocRoot : kSyncDefaultSrvDocRoot )];
        [self setLocalDocRoot:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]];
    }
    return self;
}


-(void) dealloc
{
    [_localDocRoot release];
    [_srvDocRoot release];
    [super dealloc];
}

@end
        
