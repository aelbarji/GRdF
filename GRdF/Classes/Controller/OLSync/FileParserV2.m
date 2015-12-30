//
//  FileParser.m
//  FileSynchronize
//
//  Created by zhangpanpan on 12-9-17.
//  Copyright (c) 2012年 zhangpanpan. All rights reserved.
//


#import "FileParserV2.h"

@interface FileParserV2()
{
//    NSXMLParser                     *textParser;
    NSMutableDictionary             *item;
    
    NSString                        *currentElement;
    NSMutableString                 *fileName;
    NSMutableString                 *fileCRC;
    NSMutableString                 *fileLastUpdate;
    
    NSString                        *_returnValue;
}

@end


@implementation FileParserV2
@synthesize stories=_stories;
@synthesize delegate=_delegate;

-(void)parseXMLFileAtPath:(NSString *)path
{
    _stories                = [[NSMutableArray alloc]init];
    NSURL   *xmlURL         = [NSURL URLWithString:path];
    // 2014/06/17 JPh : to solve leak issue while using initWithContentsOfURL methods
    //    textParser          = [[NSXMLParser alloc]initWithContentsOfURL:fileURL];
    NSData * dataXml        = [NSData dataWithContentsOfURL:xmlURL];
    NSXMLParser *textParser = [[NSXMLParser alloc]initWithData:dataXml];

    textParser.delegate     = self;
    [textParser parse];
    
    textParser.delegate     = nil;
    MF_COCOA_RELEASE(textParser);
    dataXml                 = nil;
}

-(void)parseXMLFileURL:(NSURL *)fileURL
{
    _stories                = [[NSMutableArray alloc]init];
    // 2014/06/17 JPh : to solve leak issue while using initWithContentsOfURL methods
    //    textParser          = [[NSXMLParser alloc]initWithContentsOfURL:fileURL];
    NSData * dataXml        = [NSData dataWithContentsOfURL:fileURL];
    NSXMLParser *textParser = [[NSXMLParser alloc]initWithData:dataXml];
    
    textParser.delegate     = self;
    [textParser parse];
    
    textParser.delegate     = nil;
    MF_COCOA_RELEASE(textParser);
    dataXml                 = nil;
}


-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if (currentElement) {
        [currentElement release];
        currentElement = nil;
    }
    currentElement  = [elementName copy];
    if ([elementName isEqualToString:kSyncXMLNodeFile]) {
        if (item) {
            [item release];
            item = nil;
        }
        if (fileName) {
            [fileName release];
            fileName = nil;
        }
        if (fileCRC) {
            [fileCRC release];
            fileCRC = nil;
        }
        if (fileLastUpdate) {
            [fileLastUpdate release];
            fileLastUpdate = nil;
        }
        item            = [[NSMutableDictionary alloc]init];
        fileName        = [[NSMutableString alloc]init];
        fileCRC         = [[NSMutableString  alloc]init];
        fileLastUpdate  = [[NSMutableString  alloc]init];
    }
    
}


-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:kSyncXMLNodeFile]) {
       
        NSString *sURL   = [fileName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [item setValue:sURL forKey:kSyncXMLNodeFileURL];
        sURL             = nil;
        
        NSString *sCRC   = [fileCRC stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [item setObject:sCRC forKey:kSyncXMLNodeFileCRC];
        sCRC             = nil;
        
        NSString *sDate  = [fileLastUpdate stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [item setObject:sDate forKey:kSyncXMLNodeLastUpdate];
        sDate            = nil;
        
        [_stories addObject:item];
    }
   
}


-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if ([currentElement isEqualToString:kSyncXMLNodeFileURL]) {
        [fileName appendString:string];
    }else if ([currentElement isEqualToString:kSyncXMLNodeFileCRC]){
        [fileCRC appendString:string];
    }else if ([currentElement isEqualToString:kSyncXMLNodeLastUpdate]){
        [fileLastUpdate appendString:string];
    }

}


-(void)parserDidEndDocument:(NSXMLParser *)parser
{
    [self performSelectorOnMainThread:@selector(tellTheDelegateItIsFinished) withObject:nil waitUntilDone:YES];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    if (_returnValue)
    {
        _returnValue=nil;
        [_returnValue release];
    }
        
    _returnValue = [[NSString stringWithFormat:@"domain: xml, error code:%i - %@",
                    [parseError code],
                    parseError.description] retain];
    
    [self performSelectorOnMainThread:@selector(tellTheDelegateItIsFinished) withObject:nil waitUntilDone:YES];
    
}

-(void) tellTheDelegateItIsFinished
{
    [_delegate FileParser:self xmlParserdidFinishParsingWithReturnValue:_returnValue];
}


-(void)dealloc
{
//    textParser = nil;
    MF_COCOA_RELEASE(_stories);
    MF_COCOA_RELEASE(item);
    MF_COCOA_RELEASE(fileName);
    MF_COCOA_RELEASE(fileCRC);
    MF_COCOA_RELEASE(fileLastUpdate);
    
    MF_COCOA_RELEASE(_returnValue);
    
    [super dealloc];
}
@end
