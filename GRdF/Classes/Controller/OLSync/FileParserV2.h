//
//  FileParser.h
//  FileSynchronize
//
//  Created by zhangpanpan on 12-9-17.
//  Copyright (c) 2012年 zhangpanpan. All rights reserved.
//

#define kSyncXMLNodeFile                        @"File"
#define kSyncXMLNodeFileURL                     @"FileName"
#define kSyncXMLNodeFileCRC                     @"FileCRC"
#define kSyncXMLNodeLastUpdate                  @"FileLastUpdate"

#import <Foundation/Foundation.h>


@protocol FileParserDelegateV2;
@interface FileParserV2 : NSObject<NSXMLParserDelegate>
{

    NSMutableArray                  *_stories;
    id <FileParserDelegateV2>         _delegate;
    
}
@property (nonatomic, retain) NSMutableArray            *stories;
@property (nonatomic, assign) id<FileParserDelegateV2>     delegate;

-(void)parseXMLFileAtPath:(NSString *)path;
-(void)parseXMLFileURL:(NSURL *)fileURL;
@end


@protocol FileParserDelegateV2 <NSObject>

-(void) FileParser:(FileParserV2 *)controller
xmlParserdidFinishParsingWithReturnValue:(NSString *) returnValue;

@end
