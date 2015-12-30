//
//  GRdFGlobals.m
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 18/11/2014.
//  Copyright (c) 2014 Onatys. All rights reserved.
//




#import "GRdFGlobals.h"
#import <CommonCrypto/CommonDigest.h>

@implementation GRdFGlobals
#pragma mark - public instance methods
#pragma mark - UI management
+ (void) setCustomSaveButton : (UIButton *) currentButton
{
    [currentButton setTitle:NSLocalizedString(@"Cancel", @"cancel") forState:UIControlStateNormal];
    
    [ currentButton setBackgroundImage:GRdF_BUTTON_CONFIRM_BACKGROUND_NORMAL forState:UIControlStateNormal ];
    [ currentButton setBackgroundImage:GRdF_BUTTON_CONFIRM_BACKGROUND_HIGHLIGHT forState:UIControlStateHighlighted ];
    currentButton.titleLabel.font       = [UIFont fontWithName:GRdF_FONT size:GRdF_BUTTON_FONT_SIZE];
    currentButton.layer.cornerRadius    = 6;
    currentButton.layer.masksToBounds   = YES;
}

+ (void) setCustomDefaultButton : (UIButton *) currentButton
{
    // default label for "close" action
    [currentButton setTitle:NSLocalizedString(@"Close", @"close") forState:UIControlStateNormal];
    
    [ currentButton setBackgroundImage:GRdF_BUTTON_DEFAULT_BACKGROUND_NORMAL forState:UIControlStateNormal ];
    [ currentButton setBackgroundImage:GRdF_BUTTON_DEFAULT_BACKGROUND_HIGHLIGHT forState:UIControlStateHighlighted ];
    currentButton.titleLabel.font       = [UIFont fontWithName:GRdF_FONT size:GRdF_BUTTON_FONT_SIZE];
    currentButton.layer.cornerRadius    = 6;
    currentButton.layer.masksToBounds   = YES;
}

+ (void) setCustomActionButton : (UIButton *) currentButton
{
    [ currentButton setBackgroundImage:GRdF_BUTTON_ACTION_BACKGROUND_NORMAL forState:UIControlStateNormal ];
    [ currentButton setBackgroundImage:GRdF_BUTTON_ACTION_BACKGROUND_HIGHLIGHT forState:UIControlStateHighlighted ];
    currentButton.titleLabel.font       = [UIFont fontWithName:GRdF_FONT size:GRdF_BUTTON_FONT_SIZE];
    currentButton.layer.cornerRadius    = 6;
    currentButton.layer.masksToBounds   = YES;
}

+ (void) setCustomDeleteButton : (UIButton *) currentButton
{
    [currentButton setTitle:NSLocalizedString(@"Delete", @"delete") forState:UIControlStateNormal];
    
    [ currentButton setBackgroundImage:GRdF_BUTTON_DELETE_BACKGROUND_NORMAL forState:UIControlStateNormal ];
    [ currentButton setBackgroundImage:GRdF_BUTTON_DELETE_BACKGROUND_HIGHLIGHT forState:UIControlStateHighlighted ];
    currentButton.titleLabel.font       = [UIFont fontWithName:GRdF_FONT size:GRdF_BUTTON_FONT_SIZE];
    currentButton.titleLabel.font       = [UIFont fontWithName:GRdF_FONT size:GRdF_BUTTON_FONT_SIZE];
    currentButton.layer.cornerRadius    = 6;
    currentButton.layer.masksToBounds   = YES;
}

+ (void) setTextField               : (UITextField *) currentTextField
{
    @autoreleasepool {
        currentTextField.backgroundColor        = GRdF_BG_TEXT_FIELD_COLOR;
        currentTextField.layer.cornerRadius     = 6.0f;
        currentTextField.layer.masksToBounds    = YES;
        currentTextField.textColor              = GRdF_TEXT_FIELD_COLOR;
        currentTextField.font                   =  [UIFont systemFontOfSize:GRdF_TEXT_FIELD_SIZE];
        currentTextField.clearButtonMode        = UITextFieldViewModeWhileEditing;
        currentTextField.borderStyle            = UITextBorderStyleRoundedRect;
    }
}

#pragma mark - user defaults management
+ (NSString *) getStringUserDefaultValueForKey:(NSString *) key
                              withDefaultValue:(NSString *) defaultValue
{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:key] )
        return [[NSUserDefaults standardUserDefaults] objectForKey:key];
    else
        return  defaultValue;
}

+ (NSInteger ) getIntegerUserDefaultValueForKey:(NSString *) key
                              usingDefaultValue:(NSInteger) defaultValue
{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:key])
        return [ [NSUserDefaults standardUserDefaults] integerForKey:key];
    else
        return  defaultValue;
}

+(void) setStringUserDefaultValue:(NSString *) value
                           forKey:(NSString *) key

{
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
   	[[NSUserDefaults standardUserDefaults] synchronize];
    
}

+(void) setIntegerUserDefaultValue:(NSInteger) value
                            forKey:(NSString *) key

{
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:key];
   	[[NSUserDefaults standardUserDefaults] synchronize];
    
}

#pragma mark - folder and path management
+(BOOL) createApplicationFolders
{
    BOOL bRetCode=TRUE;
    // Root folder
    NSString *rootFolderPath =  [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
                                 stringByAppendingPathComponent:kFolderRoot];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:rootFolderPath])
        bRetCode=[[NSFileManager defaultManager] createDirectoryAtPath:rootFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSString *documentFolderPath = [rootFolderPath
                                    stringByAppendingPathComponent:kFolderDocument];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:documentFolderPath])
        bRetCode=bRetCode && [[NSFileManager defaultManager] createDirectoryAtPath:documentFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    
    documentFolderPath  = nil;
    rootFolderPath      = nil;
    
    return bRetCode;
}

+ (NSString *) authMD5ForUserMail:(NSString *) aUserMail
                  andUserPassword:(NSString *) aUserPassword
                     andTimeStamp:(NSString *) aTimeStamp
{
    // step 1 : MD5 encrypt password
    NSString *pwdMD5 =  [[NSString alloc] initWithString:[self md5StringFromData: [aUserPassword dataUsingEncoding:NSStringEncodingConversionAllowLossy]]];
    
    
    // step 2 : build full MD5 encrypted token
    NSString *strMD5 = [[NSString alloc] initWithFormat:@"%@%@%@",
                        aUserMail,
                        pwdMD5,
                        aTimeStamp];
    
    NSString *MD5    = [[NSString alloc] initWithString:[self md5StringFromData: [strMD5 dataUsingEncoding:NSStringEncodingConversionAllowLossy]]];
    
    
    DLog(@"authMD5.end %@", MD5);
    
    NSString *result = [NSString stringWithString:MD5];
    
    MF_COCOA_RELEASE(pwdMD5);
    MF_COCOA_RELEASE(strMD5);
    MF_COCOA_RELEASE(MD5);
    
    return result;
}

+ (NSString *)md5StringFromData:(NSData *)data
{
    void *cData = malloc([data length]);
    unsigned char resultCString[16];
    [data getBytes:cData length:[data length]];
    
    CC_MD5(cData, (unsigned int)[data length], resultCString);
    free(cData);
    
    NSString *result = [NSString stringWithFormat:
                        @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                        resultCString[0], resultCString[1], resultCString[2], resultCString[3],
                        resultCString[4], resultCString[5], resultCString[6], resultCString[7],
                        resultCString[8], resultCString[9], resultCString[10], resultCString[11],
                        resultCString[12], resultCString[13], resultCString[14], resultCString[15]
                        ];
    return [result lowercaseString];
}

#pragma mark - user management
+ (NSString *) userToken
{
    NSString *aUserMail     = GRdf_USERNAME;
    NSString *aTimeStamp    = @"12345678";
    NSString *aUserPassword = GRdf_PASSWORD;
    
    NSString *token= [NSString stringWithFormat:@"%@/%@/%@",
                      aUserMail,
                      aTimeStamp,
                      [self authMD5ForUserMail:aUserMail
                                         andUserPassword:aUserPassword
                                            andTimeStamp:aTimeStamp]];

    
    return token;
}


@end
