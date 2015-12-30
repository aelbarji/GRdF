//
//  OLComboBox.m
//  OLComboBox
//
//  Created by Jean-Philippe BEAUFILS on 14/12/12.
//  Copyright (c) 2013 Onatys. All rights reserved.
//

#import "QuartzCore/QuartzCore.h"
#import "OLComboBox.h"
@interface OLComboBox()
{
    NSMutableDictionary *_comboSettings;         // global comboBox settings
    
    BOOL                _bListBoxMode;          // combobox with entry or listbox
    BOOL                _bIsNumeric;            // to filter user entry to numeric values
    BOOL                _bValuePickedFromList;  // if value is picked or manually entered buy user
    BOOL                _isEnabled;             // current enable status
    BOOL                _isExpanded;            // current expanded/collapsed status
    
    CGFloat             _tabHeight;             // tableview height (list of values)
    CGFloat             _frameHeight;           // comboBox height
    
    UIColor             *_cellLabelColor;
    float               _cellFontSize;
    
    int                 _currentIndex;
    CGRect              _frame;
    
}
@property (nonatomic, retain) NSString                  *defaultKey;    // default value/key
@property (nonatomic, retain) NSString                  *separator;     // separator used to split value & key
@property (nonatomic, retain) NSMutableArray            *tblValues;     // list of values for tableview
@property (nonatomic, retain) NSMutableArray            *tblKeys;       // list of related values'key

@property (nonatomic, retain) UITextField               *textField;     // textfield part of comboBox
@property (nonatomic, retain) UIButton                  *button;        // btn to expand/collapse comboBox
@property (nonatomic, retain) UIImageView               *imvButton;     // background image for button
@property (nonatomic, retain) UITableView               *tableViewList; // tableview used to display list of values
@end

@implementation OLComboBox
@synthesize defaultKey      = _defaultKey;
@synthesize separator       = _separator;
@synthesize tblKeys         = _tblKeys;
@synthesize tblValues       = _tblValues;
@synthesize tableViewList   = _tableViewList;
@synthesize textField       = _textField;
@synthesize button          = _button;
@synthesize imvButton       = _imvButton;

@synthesize delegate        = _delegate;


#pragma mark - public methods
- (void) clearSelection
{
    [_textField resignFirstResponder];
    if (_isExpanded)
        [self toggleExpandCollapse];
}

- (NSString *) getValue
{
    return _textField.text;
}

- (NSString *) getKey
{
    if (_currentIndex != -1 && _currentIndex < _tblKeys.count)
        return [_tblKeys objectAtIndex:_currentIndex];
    else
        return _textField.text;
}

- (void) setValuesAndKeys:( NSArray *) aValuesAndKeys
{
    self.tblKeys    = nil;
    self.tblValues  = nil;
    
    _tblValues      = [[NSMutableArray arrayWithArray:aValuesAndKeys] retain];
    _tblKeys        = [[NSMutableArray arrayWithArray:aValuesAndKeys] retain];
    
    
    
    int nbValues=[_tblValues count];
    for (int index=0; index < nbValues; index++)
    {
        NSString *val=[_tblValues objectAtIndex:index];
        NSArray *rows=[NSArray arrayWithArray:[val componentsSeparatedByString:_separator]];
        if ([rows count] > 1)
        {
            [_tblValues replaceObjectAtIndex:index  withObject:[rows objectAtIndex:0]];
            [_tblKeys replaceObjectAtIndex:index  withObject:[rows objectAtIndex:1]];
        }
    }
    
    if (_defaultKey)
        [self searchUserKeyInList:_defaultKey];

    [_tableViewList reloadData];
}

- (void) setDictSettings:(NSDictionary *) aDictSettings
{
    DLog(@"\n------- ComboBox------ \nsettingSettings: %@\n frame: %f, %f",
         aDictSettings, self.frame.size.width, self.frame.size.height);
    
    [self setFrame      :_frame];
    CGRect frame        = _frame; // self.frame;

    self.tblKeys        = nil;
    self.tblValues      = nil;
    self.defaultKey     = nil;
    self.separator      = nil;
    
    if (_comboSettings)
        MF_COCOA_RELEASE(_comboSettings);

    _comboSettings      = [[NSMutableDictionary alloc] initWithDictionary:aDictSettings];
    
    [self initBtnImages];
    
    
    if ([_comboSettings objectForKey:kComboBox_DictDefaultKey])
        self.defaultKey = [_comboSettings objectForKey:kComboBox_DictDefaultKey];
    
    if ([_comboSettings objectForKey:kComboBox_DictKeyValueSeparator])
        self.separator  = [_comboSettings objectForKey:kComboBox_DictKeyValueSeparator];
    else
        self.separator  = kComboBox_DefaultKeyValueSeparator;
    
    self.tblValues      = [NSMutableArray arrayWithArray:[_comboSettings objectForKey:kComboBox_DictValues]];
    self.tblKeys        = [NSMutableArray arrayWithArray:[_comboSettings objectForKey:kComboBox_DictValues]];

    
    int nbValues        = [_tblValues count];
    for (int index=0; index < nbValues; index++)
    {
        NSString *val   = [_tblValues objectAtIndex:index];
        NSArray *rows   = [NSArray arrayWithArray:[val componentsSeparatedByString:_separator]];
        if ([rows count] > 1)
        {
            [_tblValues replaceObjectAtIndex:index  withObject:[rows objectAtIndex:0]];
            [_tblKeys   replaceObjectAtIndex:index  withObject:[rows objectAtIndex:1]];
        }
    }
    
    if (_defaultKey)
        [self searchUserKeyInList:_defaultKey];
    
    [self setEnable     : YES];
    _isExpanded         = NO;
    _cellFontSize       = kComboBox_DefaultListFontSize;
    
    if (frame.size.height<kComboBox_MinFrameHeight)
    {
        _frameHeight    = kComboBox_MinFrameHeight;
    }
    else
    {
        _frameHeight    = frame.size.height;
    }
    
    int nbRows;
    if ([_comboSettings objectForKey:kComboBox_DictNbRows])
        nbRows          =[[_comboSettings valueForKey:kComboBox_DictNbRows] intValue];
    else
        nbRows          = floor((_frameHeight - kComboBox_Height) / kComboBox_ValueRowHeight);
    
    _tabHeight          = nbRows * kComboBox_ValueRowHeight; //_frameHeight - kComboBox_Height;
    
    
    if (_tableViewList)
    {
        [_tableViewList removeFromSuperview];
        self.tableViewList  = nil;
    }
    
    _tableViewList      = [[UITableView alloc]
                           initWithFrame:CGRectMake(0,
                                               kComboBox_Height,
                                               frame.size.width-kComboBox_Height,
                                               0)];
    _tableViewList.delegate          = self;
    _tableViewList.dataSource        = self;
    _tableViewList.backgroundColor   = GRdF_BG_TEXT_FIELD_COLOR;
    _tableViewList.separatorColor    = kComboBox_ListSepColor;
    // _tableViewList.separatorStyle    = UITableViewCellSelectionStyleBlue;
    _tableViewList.hidden            = YES;
    _tableViewList.layer.cornerRadius= kComboBox_CornerRadius;
    [self addSubview:_tableViewList];
    
    if (_textField)
    {
        [_textField removeFromSuperview];
        self.textField      = nil;
    }
    _textField              = [[UITextField alloc]
                                    initWithFrame:CGRectMake(0,
                                                             0,
                                                             frame.size.width-kComboBox_Height,
                                                             kComboBox_Height)];
    NSString *placeholder   = [_comboSettings objectForKey:kComboBox_DictPlaceholder];
    if (placeholder)
        _textField.placeholder  = [NSString stringWithString:placeholder];
//    _textField.placeholder = [_comboSettings objectForKey:kComboBox_DictPlaceholder];
    _textField.keyboardAppearance = UIKeyboardAppearanceDark;
    
    if ([_comboSettings objectForKey:kComboBox_DictPlaceholderColor])
    {
            [_textField setValue   : [_comboSettings objectForKey:kComboBox_DictPlaceholderColor] forKeyPath:@"_placeholderLabel.textColor"];
    }
    
    _textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _textField.text = (_currentIndex >= 0 ?
                       ([_tblValues count] ? [_tblValues objectAtIndex:_currentIndex]: @"") :
                       @"");
    _textField.delegate  = self;
    
    [ GRdFGlobals setTextField:_textField ];
    
    [self addSubview:_textField];
    
    _tableViewList.hidden   = YES;
    
    _bListBoxMode           = NO;
    if ([_comboSettings objectForKey:kComboBox_DictListBoxMode])
        _bListBoxMode       = [[_comboSettings objectForKey:kComboBox_DictListBoxMode] boolValue];
    _textField.enabled      = !_bListBoxMode;

    CGRect  btnFrame        = CGRectMake((_bListBoxMode ?
                                              0 :
                                              frame.size.width-kComboBox_Height),
                                              0,
                                              (_bListBoxMode ?
                                                   frame.size.width :
                                                   kComboBox_Height),
                                              kComboBox_Height);
    
    _bIsNumeric             = NO;
    
    if ([_comboSettings objectForKey:kComboBox_DictIsNumeric])
        _bIsNumeric         = [[_comboSettings objectForKey:kComboBox_DictIsNumeric] boolValue];
    
    if (_bIsNumeric)
    {
        _textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    }
    else
    {
        _textField.keyboardType = UIKeyboardTypeDefault;
    }
    
    if (_button)
    {
        [_button removeFromSuperview];
        self.button = nil;
    }
    self.button             = [UIButton buttonWithType:UIButtonTypeCustom];
    _button.frame           = btnFrame;
    
    
    
    [_button addTarget:self action:@selector(dropdownClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_button];
    
    if (_imvButton)
    {
        [_imvButton removeFromSuperview];
        self.imvButton  = nil;

    }
    
    UIImageView *imv = [[UIImageView alloc] initWithFrame:CGRectMake(frame.size.width-kComboBox_Height,
                                                                     0,
                                                                     kComboBox_Height,
                                                                     kComboBox_Height)];
    self.imvButton                  = imv;
    [imv release];
    
    [self addSubview:_imvButton];
//    [_imvButton retain];
    
    // 2014-01-27 JPhB : replace call to refreshDisplay with defaults
    _isExpanded             = NO;
    _tableViewList.hidden   = YES;
    
    CGRect sf               = self.frame;
    sf.size.height          = 30;
    self.frame              = sf;
    CGRect  tblFrame        = _tableViewList.frame;
    tblFrame.size.height    = 0;
    _tableViewList.frame    = tblFrame;
    [self setImageForCurrentState];
  
    // adjust initial display according to
    //[self refreshDisplayForCurrentStatus];
    DLog(@"\n--------> stop");
}

- (void) setDefaultKeyValue:(NSString *)aKey
{
    DLog(@"-> begin");
    
    _textField.text=@"";
    [self setDefaultKey:aKey];
    if (aKey.length)
        [self searchUserKeyInList:aKey];
    else
    {
        if (_bListBoxMode)
            _currentIndex=0;
        else
            _currentIndex=-1;
    }
    
    DLog(@"-> end");
}

- (void) setEnable:(BOOL) enable
{
    _isEnabled                              = enable;
    _textField.enabled                      = (enable ? !_bListBoxMode : NO);
    _tableViewList.userInteractionEnabled   = enable;
    _button.enabled                         = enable;
    _imvButton.hidden                       = !enable;
    
}

- (void) setListBackgroundColor:(UIColor *)backgroundColor
{
    _tableViewList.backgroundColor   = backgroundColor;
}

- (void) setListSeparatorColor:(UIColor *)separatorColor
{
    _tableViewList.separatorColor    = separatorColor;
}

- (void) setTextColor:(UIColor *)textColor
{
    [_textField setTextColor:textColor];
}

- (void) setListTextColor:(UIColor *)textColor
{
    if (_cellLabelColor)
    {
        [_cellLabelColor release];
        _cellLabelColor = nil;
    }
    _cellLabelColor = [UIColor colorWithCGColor:[textColor CGColor ]];
    [_cellLabelColor retain];
    [_tableViewList reloadData];
}

- (void) setTextFontSize:(float)fontSize
{
    _textField.font =  [UIFont systemFontOfSize:fontSize];
}

- (void) setListTextFontSize:(float)fontSize
{
    _cellFontSize = fontSize;
    [_tableViewList reloadData];
}


#pragma mark - user interface
-(void)dropdownClicked:(id)sender
{
    
    [self toggleExpandCollapse];
    
    if([self.delegate respondsToSelector:@selector(dropdownClicked:)])
    {
        [_delegate dropdownClicked:_button];
    }
    
}



#pragma mark - private methods
- (void) tellDelegateDidEndEditing
{
    if([self.delegate respondsToSelector:@selector(OLComboBox:comboBoxDidEndEditingWithValue:andKey:)])
    {
        if (_currentIndex != -1)
        {
            [_delegate OLComboBox:self
           comboBoxDidEndEditingWithValue:_textField.text
                                   andKey:[_tblKeys objectAtIndex:_currentIndex]];
        }
        else
        {
            [_delegate OLComboBox:self
           comboBoxDidEndEditingWithValue:_textField.text
                                   andKey:_textField.text];
        }
    }
}


- (void) setImageForCurrentState
{
    /*
    if (_isExpanded)
        [self.button setImage:[UIImage imageNamed:[_comboSettings objectForKey:kComboBox_DictImageBtnCollapse]] forState:UIControlStateNormal];
    else
        [self.button setImage:[UiImage imageNamed:[_comboSettings objectForKey:kComboBox_DictImageBtnExpand]] forState:UIControlStateNormal];
     */
    /*
    if (_isExpanded)
        [_imvButton setImage:[UIImage imageNamed:[_comboSettings objectForKey:kComboBox_DictImageBtnCollapse]]];
    else
        [_imvButton setImage:[UIImage imageNamed:[_comboSettings objectForKey:kComboBox_DictImageBtnExpand]]];
     */
//  2014-01-27 JPhB : replace uiimagenamed call
    NSString *imgName = [_comboSettings objectForKey:(_isExpanded ?
                                                     kComboBox_DictImageBtnCollapse :
                                                     kComboBox_DictImageBtnExpand)];
    NSArray *components = [imgName componentsSeparatedByString:@"."];
    if ([components count] > 1)
        [_imvButton setImage: [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]
                                                            pathForResource:[components objectAtIndex:0]
                                                            ofType:[components objectAtIndex:1] ]]];
    components = nil;
}

- (void) toggleExpandCollapse
{
    _isExpanded = ! _isExpanded;
    [self refreshDisplayForCurrentStatus];
    
    if (_isExpanded)
    {
        if (_bListBoxMode)
        {
            if (_delegate && [_delegate respondsToSelector:@selector(didBeginEditing:)])
            {
                [_delegate didBeginEditing:self];
            }
        }
    }
    else
    {
        if (_delegate && [_delegate respondsToSelector:@selector(didEndEditing:)])
        {
            [_delegate didEndEditing:self];
        }
    }
}

- (void) refreshDisplayForCurrentStatus
{
    if (_isExpanded)
    {
        [_textField resignFirstResponder];
        CGRect sf           = self.frame;
        sf.size.height      = _frameHeight;
        
        [self.superview bringSubviewToFront:self];
        _tableViewList.hidden= NO;
        CGRect    frame     = _tableViewList.frame;
//        2014-01-27 JPhB : why?
//        frame.size.height   = 0;
//        _tableViewList.frame     = frame;
        frame.size.height   = _tabHeight;
        
        [UIView beginAnimations:@"ResizeForKeyBoard" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        self.frame          = sf;
        _tableViewList.frame = frame;
        
        [UIView commitAnimations];
        
        
    }
    else
    {
        
        [UIView beginAnimations:@"ResizeForKeyBoard" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        
        _tableViewList.hidden= YES;
        
        
        CGRect sf           = self.frame;
        sf.size.height      = 30;
        self.frame          = sf;
        CGRect  frame       = _tableViewList.frame;
        frame.size.height   = 0;
        _tableViewList.frame     = frame;
        
        [UIView commitAnimations];
    }
    
    [self setImageForCurrentState];
    
}

#pragma mark - uitextfield notifications
- (void) textFieldDidEndEditing:(UITextField *)txtField
{
    [txtField resignFirstResponder];
    [self searchUserValueInList:txtField.text];
    [self tellDelegateDidEndEditing];
}


- (void) textFieldDidBeginEditing:(UITextField *)txtField
{
    if (_isExpanded)
    {
        [self toggleExpandCollapse];
    }
    _currentIndex = -1;
    
    if (_delegate && [_delegate respondsToSelector:@selector(didBeginEditing:)])
    {
        [_delegate didBeginEditing:self];
    }
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (_bIsNumeric)
    {
        if ([string length] == 0 && range.length > 0)
        {
            textField.text = [textField.text stringByReplacingCharactersInRange:range withString:string];
            return NO;
        }
        NSString *allowedChars=[NSString stringWithFormat:@"0123456789%@",iGRdFDecimalSep];
        NSCharacterSet *nonNumberSet = [[NSCharacterSet characterSetWithCharactersInString:allowedChars] invertedSet];
        
        if ([[[textField.text stringByReplacingCharactersInRange:range withString:string]
              componentsSeparatedByString:iGRdFDecimalSep] count] > 2 )
            return NO;
        
        if ([string stringByTrimmingCharactersInSet:nonNumberSet].length > 0)
        {
            if (_delegate && [_delegate respondsToSelector:@selector(didChange:withValue:)])
            {
                [_delegate didChange:self
                 withValue:[textField.text stringByReplacingCharactersInRange:range withString:string]];
            }
            
            return YES;
        }
        return NO;
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(didChange:withValue:)])
    {
        [_delegate didChange:self
                   withValue:[textField.text stringByReplacingCharactersInRange:range withString:string]];
    }
    
    return YES;
}


- (void) searchUserValueInList:(NSString *) aValue
{
    DLog(@"-> begin (aValue:%@)", aValue);
    
    _currentIndex = -1;

    
    int nbValues=[_tblValues count];
    for (int index=0; index < nbValues; index++)
    {
        NSString *val=[_tblValues objectAtIndex:index];
        if( [aValue caseInsensitiveCompare:val] == NSOrderedSame )
        {
            _currentIndex=index;
            _textField.text=val;
            break;
        }
    }
     
    if ((_currentIndex == -1) && _bListBoxMode)
        _textField.text=@"";
    
    DLog(@"-> end");
}

- (void) searchUserKeyInList:(NSString *) aKey
{
    DLog(@"-> begin (aKey:%@)", aKey);
    
    NSString *aKeyVal = [ NSString stringWithFormat:@"%@", aKey ];
    
    if (aKey==nil)
        return;
    
    _currentIndex=-1;
    
    int nbKeys=[_tblKeys count];
    for (int index=0; index < nbKeys; index++)
    {
        NSString *val=[_tblKeys objectAtIndex:index];
        if( [aKeyVal caseInsensitiveCompare:val] == NSOrderedSame )
        {
            _currentIndex=index;
            _textField.text=[_tblValues objectAtIndex:index];
            break;
        }
    }
    
    DLog(@"-> end");
}




- (BOOL) textFieldShouldReturn:(UITextField *)txtField
{
    return YES;
}

#pragma mark - uitableview notifications
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_tblValues count];
    
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static  NSString  *CellIdentifier = @"Cell";
    
    UITableViewCell   *cell           = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier]autorelease];
    }
    cell.textLabel.text  = [_tblValues objectAtIndex:[indexPath row]];
    cell.textLabel.font  = [UIFont systemFontOfSize:_cellFontSize];
    if (_cellLabelColor)
        cell.textLabel.textColor=_cellLabelColor;
    cell.backgroundColor = GRdF_BG_TEXT_FIELD_COLOR;
    cell.accessoryType   = UITableViewCellEditingStyleNone;
    cell.selectionStyle  = UITableViewCellSelectionStyleGray;
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kComboBox_ValueRowHeight;
}

-(void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    int row=indexPath.row;
    _currentIndex = row;
    
    _textField.text      = [_tblValues objectAtIndex:row];
    
    [_tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self dropdownClicked:nil];
    [self tellDelegateDidEndEditing];
    
}

- (void) initBtnImages
{
    
    if ( ([_comboSettings objectForKey:kComboBox_DictImageBtnCollapse] == nil) ||
         ([_comboSettings objectForKey:kComboBox_DictImageBtnExpand]   == nil) )
    {
        // use default images
        [_comboSettings setValue:kComboBox_DefaultImageBtnCollapse
                          forKey:kComboBox_DictImageBtnCollapse];
        [_comboSettings setValue:kComboBox_DefaultImageBtnExpand
                          forKey:kComboBox_DictImageBtnExpand];
    }
    
    
}

#pragma mark - initialization and memory management
- (void) awakeFromNib
{
    //    [self setDictSettings:settings];
    DLog(@"OLComboBox.awakeFromNib");
    _frame = self.frame;
    
}

- (id)initWithFrame:(CGRect)            frame
        andSettings:(NSDictionary *)    settings
{
    
    self = [super initWithFrame:frame];
    if (self) {
        self.frame      = frame;
        _frame          = frame;
        self.separator  = kComboBox_DefaultKeyValueSeparator;
        [self setDictSettings:settings ];
    }
    
    return self;
}

- (void) cleanMemory
{
    [_tableViewList removeFromSuperview];
    self.tableViewList  = nil;
    
    [_button removeFromSuperview];
    self.button         = nil;
    
    [_textField removeFromSuperview];
    self.textField      = nil;
    
    [_imvButton removeFromSuperview];
    self.imvButton      = nil;
    
    MF_COCOA_RELEASE(_cellLabelColor);
    /*
    MF_COCOA_RELEASE(_tblKeys);
    MF_COCOA_RELEASE(_tblValues);
    MF_COCOA_RELEASE(_separator);
    MF_COCOA_RELEASE(_defaultKey);
    */
    self.tblValues  = nil;
    self.tblKeys    = nil;
    self.separator  = nil;
    self.defaultKey = nil;
    
    if (_comboSettings)
        MF_COCOA_RELEASE(_comboSettings);

    _delegate       = nil;
}

-(void)dealloc
{
    DLog(@"-> deallocation");
    [self cleanMemory];
    
    /*
    if (_cellLabelColor)
        [_cellLabelColor release];
    if (_defaultKey)
        [_defaultKey    release];
    
    [_tableViewList     release];
    [_tblKeys           release];
    [_tblValues         release];
    [_textField         release];
    [_imvButton         release];
    */
    
    [super dealloc];
}

@end
