//
//  ResultListViewController.m
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 19/11/2014.
//  Copyright (c) 2014 Onatys. All rights reserved.
//

#import <MapKit/MapKit.h>

// -- interface
#import "CityInterface.h"
#import "DocumentInterface.h"

// -- tableview cell
#import "DocumentCell.h"

#import "ResultListViewController.h"

@interface ResultListViewController () <OLComboBoxDelegate,
                                        UITableViewDataSource,
                                        UITableViewDelegate>
{
    NSMutableArray          *_documents;
    
    CGRect                  _frameTblDocs;
}

@end

@implementation ResultListViewController


#pragma mark - user interface actions
- (IBAction) handleRadiusChange:(UISlider *) sender
{
    DLog(@"-> begin");

    self.searchRadius = [NSNumber numberWithInteger:sender.value];
    [self refreshRadiusLabel];

    [self clicSearch:nil];

    DLog(@"-> end");
}


- (IBAction) clicSearch:(UIButton *) sender
{
    DLog(@"-> begin");
    
    [self getData];
    
    DLog(@"-> end");
}

#pragma mark - public methods
- (void) reloadData
{
    if (_dataSourceDelegate)
    {
        NSValue *currentRegionCenter = [_dataSourceDelegate regionCenterForResultListViewController:self];
        NSValue *currentRegionSpan   = [_dataSourceDelegate regionSpanForResultListViewController:self];
        
        [_documents removeAllObjects];
        
        if (currentRegionCenter && currentRegionSpan)
        {
            // store current region definition
            CLLocationCoordinate2D center = currentRegionCenter.MKCoordinateValue;
            MKCoordinateSpan       span   = currentRegionSpan.MKCoordinateSpanValue;
            
            NSArray *docs           = [DocumentInterface documentsWithinLatitudeSpan:span.latitudeDelta
                                                                    andLongitudeSpan:span.longitudeDelta
                                                                        fromLatitude:center.latitude
                                                                        andLongitude:center.longitude];
            if (docs && docs.count)
                [_documents addObjectsFromArray:docs];
            
            docs                    = nil;
            
            
            _tblDocuments.frame = self.view.bounds;
            _tblDocuments.hidden = NO;
            
        }
        else
        {
            _tblDocuments.frame = _frameTblDocs;
        }
        
        [_tblDocuments reloadData];
    }
    else
    {
        [self getData];
    }
}


#pragma mark - OLComboBox delegate notifications
- (void) didChange:(OLComboBox *)comboBox
         withValue:(NSString *)newValue
{
    DLog(@"-> begin");
    
    if (comboBox == _cbeZipCode)
    {
        [self refreshZipCodeComboListWithValue:newValue];
        [self refreshCityNameComboListForZipCode:newValue];
    }
    else
    {
        [self refreshCityNameComboListWithValue:newValue];
    }
    
    DLog(@"-> end");
}

- (void)                OLComboBox:(OLComboBox *)   comboBox
    comboBoxDidEndEditingWithValue:(NSString *)     comboBoxValue
                            andKey:(NSString *)     comboBoxKey
{
    DLog(@"-> begin");

   if (comboBox == _cbeZipCode)
   {
       // means user selected a zipCode : need to refreh cityNames according to zipCode
       [self refreshCityNameComboListForZipCode:comboBoxValue];
       _lblNbZipCodes.text  = @"";
   }
   else
   {
        _lblNbCities.text   = @"";
       [self clicSearch:nil];
   }
    
    DLog(@"-> end");
}


#pragma mark - UITableView datasource notifications
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _documents.count;
}

- (CGFloat) tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 350.;
}

- (UITableViewCell *) tableView:(UITableView *)tableView
          cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger   row     = indexPath.row;
    
    static NSString *CellIdentifier = @"DocumentCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell==nil)
    {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"DocumentCell"
                                                                 owner:self
                                                               options:nil];
        for (id currentObject in topLevelObjects)
        {
            if ([currentObject isKindOfClass:[UITableViewCell class]]){
                cell =  (DocumentCell *) currentObject;
                break;
            }
        }
    }
    
    // Configure the cell...
    [(DocumentCell *)cell loadWithInfos:[_documents objectAtIndex:row]];
    
    
    return cell;

}

#pragma mark - UITableView delegate notifications
- (void)        tableView:(UITableView *)tableView
  didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSInteger row           = indexPath.row;
    NSDictionary *docInfos  = [_documents objectAtIndex:row];
    
    // tell delegate to load document
    if (_delegate)
        [_delegate resultListViewController:self
                     documentSelectedWithId:[docInfos objectForKey:kDocumentDict_Id]
                                andFileName:[docInfos objectForKey:kDocumentDict_FileName]];
    
    docInfos                = nil;
}

#pragma mark - private methods
- (void) getData
{
    DLog(@"-> begin");
    
    NSString *strCId = [_cbeCityName getKey];
    
    [_documents removeAllObjects];
    
    if (strCId && strCId.length)
    {
        NSNumberFormatter *fmt  = [[NSNumberFormatter alloc] init];
        fmt.numberStyle         = NSNumberFormatterDecimalStyle;
                           
        NSNumber *cityId        = [fmt numberFromString:strCId];
        NSDictionary *cInfos    = [CityInterface cityDictForCityWithId:cityId];
        
        double latitudeDelta    = _sldSearchRadius.value / 110.54; // 1 deg = 110.54 km
        double longitudeDelta   = _sldSearchRadius.value/ (cos(latitudeDelta)*111.320);  // 1 deg = 111.320 x Cos(latitude) km
        
        NSArray *docs           = [DocumentInterface documentsWithinLatitudeSpan:latitudeDelta
                                                                andLongitudeSpan:longitudeDelta
                                                                    fromLatitude:[[cInfos objectForKey:kCityDict_Latitude]
                                                                                  doubleValue]
                                                                    andLongitude:[[cInfos objectForKey:kCityDict_Longitude]
                                                                                  doubleValue]];
        if (docs && docs.count)
            [_documents addObjectsFromArray:docs];
        
        docs                    = nil;
        MF_COCOA_RELEASE(fmt);
    }

    
    [_tblDocuments reloadData];
    _tblDocuments.hidden = (_documents.count <= 0);
   
    DLog(@"-> end");
}

- (void) refreshRadiusLabel
{
    
    NSString *strRadius     = NSLocalizedString(@"Search_RadiusMask",
                                                @"");
    strRadius = [strRadius stringByReplacingOccurrencesOfString:@"[radius]"
                                                     withString:[NSString stringWithFormat:@"%@",
                                                                 _searchRadius]];
    _lblSearchRadius.text   = strRadius;
    strRadius               = nil;
}

// -- rebuild list of city names according to selected zipCode
- (void) refreshCityNameComboListForZipCode:(NSString *) aZipCode
{
    DLog(@"-> begin");
    
    // search for list of city names only at least 3 digits entered
    _lblNbCities.text = @"";
    
    NSString *curCity = [NSString stringWithFormat:@"%@|%@",
                         [_cbeCityName getValue],
                         [_cbeCityName getKey]];
    
    NSArray *cities = [CityInterface citiesForZipCode:aZipCode];
    
    [_cbeCityName setValuesAndKeys:cities];
    if ([cities indexOfObject:curCity] == NSNotFound)
        [_cbeCityName setDefaultKeyValue:@""];
    
    curCity         = nil;
    
    if (cities.count > 0)
    {
        NSString *lbl = [[NSLocalizedString(@"Search_NbCityNamesMask",
                                            @"") stringByReplacingOccurrencesOfString:@"[nb]"
                          withString:[NSString stringWithFormat:@"%.0lu", (unsigned long)cities.count]] stringByReplacingOccurrencesOfString:@"(s)"
                         withString:(cities.count > 1 ? @"s" : @"")];
        
        _lblNbCities.text = lbl;
        
        lbl             = nil;
    }
    else
        _lblNbCities.text = @"";
    
    cities          = nil;
    
    // hide previous document list
    _tblDocuments.hidden = YES;
    
    DLog(@"-> end");
}

// -- rebuild list of city names according to current value (prefix)
- (void) refreshCityNameComboListWithValue:(NSString *) aValue
{
    DLog(@"-> begin");
    
    // search for list of city names only at least 3 digits entered
    _lblNbCities.text = @"";
    
    if (aValue && aValue.length > 2)
    {
        NSArray *cities = [CityInterface citiesForPrefix:aValue
                                           andPrefixLength:aValue.length
                                              andZipCode:[_cbeZipCode getKey]];
        
        [_cbeCityName setValuesAndKeys:cities];
        
        if (cities.count > 0)
        {
            NSString *lbl = [[NSLocalizedString(@"Search_NbCityNamesMask",
                                                @"") stringByReplacingOccurrencesOfString:@"[nb]"
                              withString:[NSString stringWithFormat:@"%.0lu", (unsigned long)cities.count]] stringByReplacingOccurrencesOfString:@"(s)"
                             withString:(cities.count > 1 ? @"s" : @"")];
            
            _lblNbCities.text = lbl;
            
            lbl             = nil;
        }
        else
            _lblNbCities.text = @"";

        cities          = nil;
    }
    
    // hide previous document list
    _tblDocuments.hidden = YES;
    
    DLog(@"-> end");
}

// -- rebuild list of zip codes according to current value
- (void) refreshZipCodeComboListWithValue:(NSString *) aValue
{
    DLog(@"-> begin");
    
    // search for list of zipcodes only at least 2 digits entered
    _lblNbZipCodes.text = @"";
    
    if (aValue && aValue.length > 1)
    {
        NSArray *zipCodes = [CityInterface zipCodesForPrefix:aValue];
        
        [_cbeZipCode setValuesAndKeys:zipCodes];
        
        if (zipCodes.count > 0)
        {
            NSString *lbl = [[NSLocalizedString(@"Search_NbZipCodesMask",
                                                @"") stringByReplacingOccurrencesOfString:@"[nb]"
                              withString:[NSString stringWithFormat:@"%.0lu", (unsigned long)zipCodes.count]] stringByReplacingOccurrencesOfString:@"(s)"
                             withString:(zipCodes.count > 1 ? @"s" : @"")];
            
            _lblNbZipCodes.text = lbl;
            
            lbl             = nil;        }
        else
        {
            _lblNbZipCodes.text= @"";
        }
        
        zipCodes        = nil;
    }
    
    // hide previous document list
    _tblDocuments.hidden = YES;
    
    DLog(@"-> end");
}

// -- zipCode comboBox intialization
- (void) setupComboForZipCodeWithValue:(NSString *) aValue
{
    DLog(@"-> begin");
    
    NSMutableDictionary *dictCombo  = [NSMutableDictionary dictionary];
    
    [dictCombo setObject: [NSNumber numberWithBool:NO]
                  forKey:kComboBox_DictListBoxMode];
    [dictCombo setObject:[NSNumber numberWithBool:YES]
                  forKey:kComboBox_DictIsNumeric];
    [dictCombo setObject:NSLocalizedString(@"Search_pZipCode", @"")
                  forKey:kComboBox_DictPlaceholder];
    
    // search for list of zipcodes only at least 2 digits entered
    if (aValue && aValue.length > 1)
    {
        NSArray *zipCodes = [CityInterface zipCodesForPrefix:aValue];
        [dictCombo setObject:zipCodes
                      forKey:kComboBox_DictValues];
        [dictCombo setObject: [NSNumber numberWithDouble:MIN(6,zipCodes.count)]
                      forKey:kComboBox_DictNbRows];
        
        zipCodes        = nil;
    }
    else
    {
        [dictCombo setObject:(aValue ? @[aValue] : @[])
                      forKey:kComboBox_DictValues];
        [dictCombo setObject: [NSNumber numberWithDouble:6]
                      forKey:kComboBox_DictNbRows];
    }

    [dictCombo setObject:(aValue ? aValue : @"")
                  forKey:kComboBox_DictDefaultKey];
    
    [(OLComboBox *)_cbeZipCode setDictSettings        :dictCombo];
    [(OLComboBox *)_cbeZipCode setListBackgroundColor :GRdF_LABEL_BACKGROUND_COLOR];
    [(OLComboBox *)_cbeZipCode setListSeparatorColor  :[UIColor whiteColor]];
    [(OLComboBox *)_cbeZipCode setTextColor           :GRdF_LABEL_TEXT_COLOR];
    [(OLComboBox *)_cbeZipCode setListTextColor       :GRdF_LABEL_TEXT_COLOR];
    
    ((OLComboBox *)_cbeZipCode).delegate    = self;
    
    
    dictCombo               = nil;
    DLog(@"-> end");
}

// -- cityName comboBox intialization
- (void) setupComboForCityNameWithValue:(NSString *) aValue
{
    DLog(@"-> begin");
    
    NSMutableDictionary *dictCombo  = [NSMutableDictionary dictionary];
    
    [dictCombo setObject: [NSNumber numberWithBool:NO]
                  forKey:kComboBox_DictListBoxMode];
    [dictCombo setObject:[NSNumber numberWithBool:NO]
                  forKey:kComboBox_DictIsNumeric];
    [dictCombo setObject:NSLocalizedString(@"Search_pCityName", @"")
                  forKey:kComboBox_DictPlaceholder];
    
    // search for list of city names only at least 3 digits entered
    if (aValue && aValue.length > 2)
    {
        NSArray *cities = [CityInterface citiesForPrefix:aValue
                                         andPrefixLength:aValue.length
                                              andZipCode:nil];
        [dictCombo setObject:cities
                      forKey:kComboBox_DictValues];
        [dictCombo setObject: [NSNumber numberWithDouble:MIN(6,cities.count)]
                      forKey:kComboBox_DictNbRows];
        
        cities        = nil;
    }
    else
    {
        [dictCombo setObject:(aValue ? @[aValue] : @[])
                      forKey:kComboBox_DictValues];
        [dictCombo setObject: [NSNumber numberWithDouble:6]
                      forKey:kComboBox_DictNbRows];
    }
    
    [dictCombo setObject:(aValue ? aValue : @"")
                  forKey:kComboBox_DictDefaultKey];
    
    [(OLComboBox *)_cbeCityName setDictSettings        :dictCombo];
    [(OLComboBox *)_cbeCityName setListBackgroundColor :GRdF_LABEL_BACKGROUND_COLOR];
    [(OLComboBox *)_cbeCityName setListSeparatorColor  :[UIColor whiteColor]];
    [(OLComboBox *)_cbeCityName setTextColor           :GRdF_LABEL_TEXT_COLOR];
    [(OLComboBox *)_cbeCityName setListTextColor       :GRdF_LABEL_TEXT_COLOR];
    
    ((OLComboBox *)_cbeCityName).delegate    = self;
    
    
    dictCombo               = nil;
    
    DLog(@"-> end");
}

- (void) configureUI
{
    DLog(@"-> begin");

    [ GRdFGlobals setCustomDefaultButton:_btnSearch];
    
    _sldSearchRadius.maximumValue   = GRdF_SEARCH_RADIUS_MAX;
    _sldSearchRadius.value          = self.searchRadius.integerValue;
    
    DLog(@"-> end");
}

- (void) localize
{
    DLog(@"-> begin");
    
    self.title              = NSLocalizedString(@"Result_List",
                                                @"");

    _lblZipCode.text        = NSLocalizedString(@"Search_ZipCode",
                                                @"");
    _lblCityName.text       = NSLocalizedString(@"Search_CityName",
                                                @"");
    _lblNoDocument.text     = NSLocalizedString(@"Search_NoResult",
                                                @"");

    [self refreshRadiusLabel];

    [_btnSearch setTitle:NSLocalizedString(@"Search", @"")
                forState:UIControlStateNormal];
    
    DLog(@"-> end");
}

- (void) cleanMemory
{
    DLog(@"-> begin");
    
    MF_COCOA_RELEASE(_documents);

    self.searchRadius   = nil;
    
    DLog(@"-> end");
}

#pragma mark - initialization and memory management
- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil
                           bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.searchRadius   = [NSNumber numberWithInteger:GRdF_SEARCH_RADIUS_DEFAULT];
        
        _documents          = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _frameTblDocs       = _tblDocuments.frame;
    
    [self configureUI];
    [self localize];
    
    [self setupComboForZipCodeWithValue:nil];
    [self setupComboForCityNameWithValue:nil];
    
    [self getData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) dealloc
{
    DLog(@"-> deallocating");
    
    [self cleanMemory];
    
    MF_COCOA_RELEASE(_btnSearch);
    MF_COCOA_RELEASE(_lblZipCode);
    MF_COCOA_RELEASE(_lblCityName);
    MF_COCOA_RELEASE(_lblSearchRadius);
    MF_COCOA_RELEASE(_cbeZipCode);
    MF_COCOA_RELEASE(_cbeCityName);
    MF_COCOA_RELEASE(_lblNbZipCodes);
    MF_COCOA_RELEASE(_lblNbCities);
    MF_COCOA_RELEASE(_sldSearchRadius);
    
    MF_COCOA_RELEASE(_tblDocuments);

    MF_COCOA_RELEASE(_cbeZipCode);
    MF_COCOA_RELEASE(_cbeCityName);
    
    self.view   = nil;
    [_lblNoDocument release];
    [super dealloc];
}

@end
