//
//  OLComboBox.h
//  OLComboBox
//
//  Created by Jean-Philippe BEAUFILS on 14/12/12.
//  Copyright (c) 2013 Onatys. All rights reserved.
//


#define kComboBox_DictPlaceholder           @"ObjectPlaceholder"
#define kComboBox_DictPlaceholderColor      @"ObjectPlaceholderColor"
#define kComboBox_DictValues                @"ObjectValue"
#define kComboBox_DictImageBtnCollapse      @"ObjectImageFileNameCollapse"
#define kComboBox_DictImageBtnExpand        @"ObjectImageFileNameExpand"
#define kComboBox_DictNbRows                @"ObjectNbRows"
#define kComboBox_DictListBoxMode           @"ObjectListBoxMode"
#define kComboBox_DictKeyValueSeparator     @"ObjectSeparator"
#define kComboBox_DictDefaultKey            @"ObjectDefaultKey"
#define kComboBox_DictIsNumeric             @"ObjectIsNumeric"

#define kComboBox_DefaultKeyValueSeparator  @"|"

#define kComboBox_DefaultImageBtnCollapse   @"btnCollapse.png"
#define kComboBox_DefaultImageBtnExpand     @"btnExpand.png"
#define kComboBox_DefaultListFontSize       14.0
#define kComboBox_DefaultTextFontSize       14.0


#define kComboBox_Height                    30
#define kComboBox_MinFrameHeight            250
#define kComboBox_ValueRowHeight            50
#define kComboBox_ListSepColor              [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0 ]
#define kComboBox_CornerRadius              10

#import <UIKit/UIKit.h>


@protocol OLComboBoxDelegate;

@interface OLComboBox : UIView <UITableViewDataSource,
                            UITableViewDelegate,
                            UITextFieldDelegate>
{
    id <OLComboBoxDelegate>  _delegate;
}

@property (nonatomic, assign) id <OLComboBoxDelegate>    delegate;

- (NSString *) getValue;
- (NSString *) getKey;

- (void) setValuesAndKeys:( NSArray *) aValuesAndKeys;

- (void) setDictSettings:(NSDictionary *) aDictSettings;

- (id)initWithFrame             :(CGRect)           frame
                     andSettings:(NSDictionary *)   settings;
- (void) setDefaultKeyValue     :(NSString *) aKey;

- (void) setEnable              :(BOOL)             enable;
- (void) setListBackgroundColor :(UIColor *)        backgroundColor;
- (void) setListSeparatorColor  :(UIColor *)        separatorColor;
- (void) setTextColor           :(UIColor *)        textColor;
- (void) setListTextColor       :(UIColor *)        textColor;
- (void) setTextFontSize        :(float)            fontSize;
- (void) setListTextFontSize    :(float)            fontSize;

- (void) clearSelection;
@end



@protocol OLComboBoxDelegate <NSObject>
@optional
- (void) dropdownClicked        :(UIButton *)       button;
- (void) didBeginEditing        :(OLComboBox *)     comboBox;
- (void) didEndEditing          :(OLComboBox *)     comboBox;
- (void) didChange              :(OLComboBox *)     comboBox
            withValue           :(NSString *)       newValue;

@required
- (void) OLComboBox:            (OLComboBox *)      comboBox
comboBoxDidEndEditingWithValue: (NSString *)        comboBoxValue
                        andKey: (NSString *)        comboBoxKey;


@end
