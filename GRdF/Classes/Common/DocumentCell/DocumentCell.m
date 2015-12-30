//
//  DocumentCell.m
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 23/12/13.
//  Copyright (c) 2013 Onatys. All rights reserved.
//

#define kThumbnail_width    350
#define kThumbnail_height   350


#import "DocumentInterface.h"

#import "DocumentCell.h"


@implementation DocumentCell
{
}


#pragma mark - public methods

- (void) loadWithInfos:(NSDictionary *)aInfos
{

    NSString *title     = [aInfos objectForKey:kDocumentDict_Title];
    NSString *desc      = [aInfos objectForKey:kDocumentDict_Description];
    NSString *cityName  = [aInfos objectForKey:kDocumentDict_CityName];
    NSString *fileName  = [aInfos objectForKey:kDocumentDict_FileName];
    
    _lblTitle.text          = (title    ? title     : @"-");
    _lblNotes.text          = (desc     ? desc      : @"" );
    _lblInfos.text          = (cityName ? cityName  : @"");
    

    [self loadThumbnailForFileName:fileName
                       inImageView:_imvThumbnail];
    
    fileName            = nil;
    cityName            = nil;
    desc                = nil;
    title               = nil;
    
}



#pragma mark - private methods

- (void) loadThumbnailForFileName:(NSString *)      aFileName
                      inImageView:(UIImageView *)   aImgView
{
    NSString* thumbnailPath = [DocumentInterface thumbnailPathForFileName:aFileName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:thumbnailPath])
    {
        // generate thumbnail async
        dispatch_queue_t asyncQueueThumbNail;
        asyncQueueThumbNail = dispatch_queue_create("com.onatys.grdfasyncqueue",
                                                    DISPATCH_QUEUE_SERIAL);
        
        // step 1 : place "not synched" img in obj
        [aImgView setImage:[UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"not_synchronized" ofType: @"png"]]];
        
        // step 2 : create new thumbnail async
        dispatch_async(asyncQueueThumbNail, ^{
            DLog(@"start thumbnail creation");
            
            NSString *pdfFilePath   = [DocumentInterface documentPathForFileName:aFileName
                                                                     withDefault:nil];
            
            CFStringRef path = CFStringCreateWithCString (NULL, [pdfFilePath UTF8String], kCFStringEncodingUTF8);
            CFURLRef url = CFURLCreateWithFileSystemPath (NULL, path, kCFURLPOSIXPathStyle, 0);
            
            // load pdf
            CGPDFDocumentRef pdfRef = CGPDFDocumentCreateWithURL(url);
            
            CFRelease(path);
            CFRelease(url);
            
            CGSize thumbSize        = CGSizeMake(kThumbnail_width, kThumbnail_height);
            UIGraphicsBeginImageContext(thumbSize);
            CGContextRef ctx        = UIGraphicsGetCurrentContext();
            CGContextTranslateCTM(ctx, 0, thumbSize.height);
            CGContextConcatCTM(ctx, CGAffineTransformMakeScale(1.,-1));

            CGPDFPageRef pdfPage    = CGPDFDocumentGetPage (pdfRef, 1);
            CGAffineTransform pdfTransform = CGPDFPageGetDrawingTransform(pdfPage,
                                                                          kCGPDFCropBox,
                                                                          CGRectMake(0,0,thumbSize.width, thumbSize.height),
                                                                          0,
                                                                          true);

            CGContextConcatCTM(ctx, pdfTransform);
            CGContextDrawPDFPage(ctx, pdfPage);
            
            UIImage* imgThumbnail   = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            CGPDFDocumentRelease(pdfRef);
            
            BOOL bRetCode           = [UIImageJPEGRepresentation(imgThumbnail, 0.5)
                                       writeToFile:thumbnailPath
                                       atomically:NO];
            
            DLog(@"new thumbnail image saved : %@", (bRetCode ? @"ok" : @"ko"));
            
            // third : place new image in obj from main queue
            dispatch_async(dispatch_get_main_queue(), ^{
                if (bRetCode)
                {
                    DLog(@"load created thumbnail");
                    [aImgView setImage:[UIImage imageWithContentsOfFile:thumbnailPath]];
                }
            });
            
            pdfPage                 = nil;
            imgThumbnail            = nil;
            pdfFilePath             = nil;
            
        });
        
        dispatch_release(asyncQueueThumbNail);
        
    }
    else
    {
        [aImgView setImage:[UIImage imageWithContentsOfFile:thumbnailPath]];
    }
    
    
}




#pragma mark - initialization and memory management
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc {
    MF_COCOA_RELEASE(_lblTitle);
    MF_COCOA_RELEASE(_lblNotes);
    MF_COCOA_RELEASE(_lblInfos);
    MF_COCOA_RELEASE(_imvThumbnail);
    
    [super dealloc];
}
@end
