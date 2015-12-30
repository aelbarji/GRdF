//
//  SettingsViewController.h
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 19/09/13.
//  Copyright (c) 2013 Onatys. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController {
    
}

//  --- headers ---
@property (retain, nonatomic) IBOutlet UILabel      *lblApplicationDetails;

// --- version ----
@property (retain, nonatomic) IBOutlet UILabel      *versionTitleLabel;
@property (retain, nonatomic) IBOutlet UILabel      *versionValueLabel;
@property (retain, nonatomic) IBOutlet UIButton     *versionUpdateButton;

// --- synchronization ---
@property (retain, nonatomic) IBOutlet UILabel      *syncTitleLabel;
@property (retain, nonatomic) IBOutlet UILabel      *syncFullLabel;
@property (retain, nonatomic) IBOutlet UILabel      *syncFullValueLabel;
@property (retain, nonatomic) IBOutlet UIButton     *syncInitButton;

// -- disclaimer & licence
@property (retain, nonatomic) IBOutlet UITextView *txtvLicence;
@property (retain, nonatomic) IBOutlet UITextView *txtvDisclaimer;

-(IBAction) clicUpdateVersion:(id)sender;
-(IBAction) clicInitSync:(id)sender;

@end
