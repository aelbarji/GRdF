//
//  LocalFiles.h
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 18/11/2014.
//  Copyright (c) 2014 Onatys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface LocalFiles : NSManagedObject

@property (nonatomic, retain) NSString * localFileCRC;
@property (nonatomic, retain) NSString * localFileLastUpdate;
@property (nonatomic, retain) NSString * localFileStatus;
@property (nonatomic, retain) NSString * localFileURL;

@end
