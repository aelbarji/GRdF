//
//  GRdFGlobals.h
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 18/11/2014.
//  Copyright (c) 2014 Onatys. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GRdFGlobals : NSObject


#pragma mark - common UI actions
+ (void) setCustomSaveButton    : (UIButton *)      currentButton;
+ (void) setCustomDefaultButton : (UIButton *)      currentButton;
+ (void) setCustomDeleteButton  : (UIButton *)      currentButton;
+ (void) setCustomActionButton  : (UIButton *)      currentButton;
+ (void) setTextField           : (UITextField *)   currentTextField;
#pragma mark - user defaults management
+ (NSString *)      getStringUserDefaultValueForKey:    (NSString *)    key
                                   withDefaultValue:    (NSString *)    defaultValue;
+ (NSInteger )      getIntegerUserDefaultValueForKey:   (NSString *)    key
                                   usingDefaultValue:   (NSInteger)     defaultValue;
+ (void)            setStringUserDefaultValue:          (NSString *)    value
                                       forKey:          (NSString *)    key;
+ (void)            setIntegerUserDefaultValue:         (NSInteger)     value
                                        forKey:         (NSString *)    key;

#pragma mark - folder and path management
+(BOOL)             createApplicationFolders ;


#pragma mark - user management
+ (NSString *) userToken;


@end
