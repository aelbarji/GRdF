//
//  ResultListViewController.h
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 19/11/2014.
//  Copyright (c) 2014 Onatys. All rights reserved.
//

//@class OLComboBox;

#import <UIKit/UIKit.h>

@protocol ResultListViewControllerDataSource;
@protocol ResultListViewControllerDelegate;

@interface ResultListViewController : UIViewController 
// class properties
@property (retain, nonatomic) NSNumber *searchRadius;
@property (assign, nonatomic) id <ResultListViewControllerDataSource> dataSourceDelegate;
@property (assign, nonatomic) id <ResultListViewControllerDelegate> delegate;

// UI components
@property (retain, nonatomic) IBOutlet UILabel      *lblZipCode;
@property (retain, nonatomic) IBOutlet UILabel      *lblCityName;
@property (retain, nonatomic) IBOutlet UILabel      *lblSearchRadius;
@property (retain, nonatomic) IBOutlet UILabel      *lblNbZipCodes;
@property (retain, nonatomic) IBOutlet UILabel      *lblNbCities;


@property (retain, nonatomic) IBOutlet UISlider     *sldSearchRadius;
@property (retain, nonatomic) IBOutlet UIButton     *btnSearch;

@property (retain, nonatomic) IBOutlet OLComboBox *cbeZipCode;
@property (retain, nonatomic) IBOutlet OLComboBox *cbeCityName;


@property (retain, nonatomic) IBOutlet UITableView *tblDocuments;
@property (retain, nonatomic) IBOutlet UILabel *lblNoDocument;

// public instance methods
- (void) reloadData;

@end

@protocol ResultListViewControllerDataSource

- (NSValue *) regionCenterForResultListViewController: (ResultListViewController *)  aController;
- (NSValue *) regionSpanForResultListViewController  : (ResultListViewController *)  aController;


@end


@protocol ResultListViewControllerDelegate

- (void) resultListViewController:(ResultListViewController *)  aController
           documentSelectedWithId:(NSNumber *)                  aDocumentId
                      andFileName:(NSString *) aFileName;

@end