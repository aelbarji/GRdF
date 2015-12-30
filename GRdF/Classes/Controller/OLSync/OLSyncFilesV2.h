//
//  OLSyncFiles.h
//  FileSynchronize
//
//  Created by zhangpanpan on 12-9-17.
//  Copyright (c) 2012年 zhangpanpan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileParserV2.h"


#define kSyncLocalFilesEntityName               @"LocalFiles"

#define kSyncAttrLocalFileURL                   @"localFileURL"
#define kSyncAttrLocalFileCRC                   @"localFileCRC"
#define kSyncAttrLocalFileStatus                @"localFileStatus"
#define kSyncAttrLocalFileLastUpdate            @"localFileLastUpdate"

// file management
#define kSyncStatusPendingUploadCreate          @"UC"
#define kSyncStatusPendingUploadUpdate          @"UU"
#define kSyncStatusPendingUploadDelete          @"UD"
#define kSyncStatusPendingDownload              @"D"
#define kSyncStatusReceived                     @"R"
#define kSyncStatusTransmited                   @"T"
// bloc management
#define kSyncStatusBlockPendingUpload           @"BU"
#define kSyncStatusBlockTransmitted             @"BT"  

#define kSyncDefaultSrvDocRoot                  @"http://localhost:8888/onatys"


@protocol OLSyncFilesDelegateV2;

@interface OLSyncFilesV2 : NSObject <FileParserDelegateV2>
{
    id <OLSyncFilesDelegateV2>      _delegate;
    id                              _object;
}
@property (assign, nonatomic)   id <OLSyncFilesDelegateV2>      delegate;
@property (assign, nonatomic)   id                              object;

+ (NSString *)          md5StringFromData: (NSData *)                       data;

+ (NSString *) md5StringFromRelativeFileWithPath: (NSString *)              filePath;

+ (BOOL) localFileIsSynchedForRelativeFilePath:(NSString *)                     relativeFilePath
                                     withStore:(NSPersistentStoreCoordinator *) coordinator;

+ (BOOL)      logLocalFileChangeWithStore: (NSPersistentStoreCoordinator *) coordinator
                      forRelativeFilePath: (NSString *)                     relativeFilePath
                                andStatus: (NSString *)                     aStatus
                            andUpdateDate: (NSString *)                     fileLastUpdate;

+ (BOOL)      logLocalFileChangeWithStore: (NSPersistentStoreCoordinator *) coordinator
                      forRelativeFilePath: (NSString *)                     relativeFilePath
                              forCreation: (BOOL)                           bCreate
                            andUpdateDate: (NSString *)                     fileLastUpdate;

+ (BOOL)   toggleLocalFileStatusWithStore: (NSPersistentStoreCoordinator *) coordinator
                      forRelativeFilePath: (NSString *)                     relativeFilePath;

+ (BOOL)       truncateLocalFileWithStore: (NSPersistentStoreCoordinator *) coordinator;

+ (BOOL)    deleteLocalFileEntryWithStore: (NSPersistentStoreCoordinator *) coordinator
                      forRelativeFilePath: (NSString *)                     relativeFilePath;

+ (NSArray *) localFilesToUploadWithStore: (NSPersistentStoreCoordinator *) coordinator
                                forStatus: (NSString *)                     syncStatus
                         cleanNoFileEntry: (BOOL)                           bCleanNoFileEntry;


- (id)                      initWithStore: (NSPersistentStoreCoordinator *) store
                            andSrvDocRoot: (NSString *)                     srvDocRoot;

- (void)         syncLocalFilesFromXMLURL: (NSURL *)                        XMLURL;




@end


@protocol OLSyncFilesDelegateV2

-(void)                     OLSyncFiles: (OLSyncFilesV2 *)                  controller
    fileSynchronizationDidEndWithStatus: (BOOL)                             status
                             andMessage: (NSString *)                       message;

-(void)                     OLSyncFiles: (OLSyncFilesV2 *)                  controller
                 numberOfFilesToControl: (int)                              nbrOfFiles
                             withObject: (id)                               object;

-(void)                     OLSyncFiles: (OLSyncFilesV2 *)                  controller
                 numberOfFilesProcessed: (int)                              nbrOfFilesProcessed
                                   upon: (int)                              nbrOfFiles
                             withObject: (id)                               object;

-(void)                     OLSyncFiles: (OLSyncFilesV2 *)                  controller
                   processingFileNumber: (int)                              nbrOfFilesProcessed
                                   upon: (int)                              nbrOfFiles
                           withFileName: (NSString *)                       fileName
                             withObject: (id)                               object;

-(void)                     OLSyncFiles: (OLSyncFilesV2 *)                  controller
                errorProcessingFileName: (NSString *)                       fileName;

-(void)                     OLSyncFiles: (OLSyncFilesV2 *)                  controller
                     remainingFileNames: (NSArray *)                        fileNames;


@end
