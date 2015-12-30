//
//  OLSyncDatabase.h
//  Synchro_bdd
//
//  Created by yangdong on 12-9-17.
//  Copyright (c) 2012年 yangdong. All rights reserved.
//

#define kDefaultSyncDateFormat          @"yyyy/MM/dd HH:mm:ss"
#define kDefaultDecimalSeparator        @","
#define kSyncEntityPrefix               @"Sync"

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
@protocol OLSyncDatabaseDelegateV2;

@interface OLSyncDatabaseV2 : NSObject<NSXMLParserDelegate>
{
    id <OLSyncDatabaseDelegateV2>           _delegate;
}
@property (assign, nonatomic)   id <OLSyncDatabaseDelegateV2>   delegate;

- (id)                initWithStore: (NSPersistentStoreCoordinator *) store;

- (id) initWithManagedObjectContext: (NSManagedObjectContext *) context;

- (NSString *)      OLSyncBDDEntity: (NSString *)               entityName
                     withAttributes: (NSArray *)                entityAttributes
                    usingDateFormat: (NSString *)               dateFormat
              usingDecimalSeparator: (NSString *)               decimalSeparator
                withXmlStreamString: (NSURL *)                  xmlStreamURL;

- (NSArray *)fetchRecordsFromEntity: (NSString *)               entityName
           withManagedObjectContext: (NSManagedObjectContext *) moc;



@end

@protocol OLSyncDatabaseDelegateV2 <NSObject>
@optional
-(void) databaseSynchronizationDidEnd: (OLSyncDatabaseV2 *) controller
                           withStatus: (BOOL)               status
                           andMessage: (NSString *)         message;

@end