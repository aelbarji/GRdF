//
//  SettingsViewController.m
//  OMBS
//
//  Created by Jean-Philippe BEAUFILS on 19/09/13.
//  Copyright (c) 2013 Onatys. All rights reserved.
//
#import "MBProgressHUD.h"
#import "SettingsViewController.h"
#import "AppDelegate.h"
#import "SynchroViewController.h"

@interface SettingsViewController () <UITextViewDelegate,
                                        MBProgressHUDDelegate>

@end

@implementation SettingsViewController

#pragma mark - user interface actions


// Clic update version
-(IBAction) clicUpdateVersion:(id)sender
{
    // LOG
    DLog(@" -> begin");
    
    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:OL_UPDATE_URL_GRdF]];
    
    // LOG
    DLog(@" -> end");
}

// Clic force sync
-(IBAction) clicInitSync:(id)sender
{
    // LOG
    DLog(@" -> begin");
    // clean timestamps to force download
    [SynchroViewController cleanDatabaseTimestamps];
    
    // clean last synchronization execution date
    NSString *strDate = [[NSDate dateWithTimeIntervalSince1970:1]intervalStringSince1970GMT];
    [GRdFGlobals setStringUserDefaultValue:@""
                                  forKey:kNSUserDefaultsFullSync];
    [GRdFGlobals setStringUserDefaultValue:strDate
                                  forKey:kNSUserDefaultsLastSync];
    [NSThread detachNewThreadSelector:@selector(handleFullSynchroRequest)
                             toTarget:self
                           withObject:nil];
    strDate         = nil;
    
 // LOG
    DLog(@" -> end");
}



#pragma mark - MBProgressHUD notifications
- (void) hudWasHidden:(MBProgressHUD *)hud
{
    [hud removeFromSuperview];
    hud = nil;
}

#pragma mark - private methods
- (void) handleFullSynchroRequest
{
    DLog(@"-> begin");
    
    [NSThread sleepForTimeInterval:0.2];
    // fires synchronization
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        // fires synchronization
        [iGRdFDelegate launchSynchro ];
    }];
    
    DLog(@"-> end");
}



- (void) localize
{
    self.title                      = NSLocalizedString(@"Settings",
                                                        @"");
    
    _txtvDisclaimer.text            = NSLocalizedString(@"Disclaimer",
                                                        @"");

    _txtvLicence.text               = NSLocalizedString(@"Licence",
                                                        @"");
    
    _lblApplicationDetails.text     = NSLocalizedString(@"Settings_AppDetails",
                                                        @"Application details");
    
    _versionTitleLabel.text         = NSLocalizedString(@"Settings_VersionTitle",
                                                        @"Version");
    
#ifdef SR_ENVIRONMENT_DEV
    _versionTitleLabel.text         = NSLocalizedString(@"Settings_VersionTitle_alpha",
                                                        @"Version");
#else
#ifdef SR_ENVIRONMENT_QUAL
    _versionTitleLabel.text         = NSLocalizedString(@"Settings_VersionTitle_beta",
                                                        @"Version");
#endif
#endif
    

    
    _syncTitleLabel.text            = NSLocalizedString(@"Settings_SyncTitle",
                                                        @"Synchronisation");
    _syncFullLabel.text             = NSLocalizedString(@"Settings_SyncFullTitle",
                                                        @"Full");

    [ _versionUpdateButton setTitle:NSLocalizedString(@"Settings_BtnUpdate",
                                                      @"Update")
                           forState:UIControlStateNormal ];
    [ _syncInitButton setTitle:NSLocalizedString(@"Settings_BtnForceSync",
                                                 @"Force")
                      forState:UIControlStateNormal ];

}

- (void) configureUI
{
    
    [ GRdFGlobals setCustomDefaultButton:_versionUpdateButton];
    [ GRdFGlobals setCustomDefaultButton:_syncInitButton];

}




// Set version values
- (void) setVersionValues
{
    _versionValueLabel.text = [ NSString stringWithFormat:@"v %@ (Build %@)",
                               [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
                               [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] ];
}

// Set sync values
- (void) setSyncValues
{
    NSDateFormatter *formatter      = [[NSDateFormatter alloc] init];
    formatter.dateStyle             = NSDateFormatterShortStyle;
    
    NSDate *lastFullSyncDate        = [NSDate dateWithIntervalSince1970GMT:[ [NSUserDefaults standardUserDefaults]
                                                                 stringForKey:kNSUserDefaultsFullSync].integerValue];

    if (lastFullSyncDate)
        _syncFullValueLabel.text    = [formatter stringFromDate:lastFullSyncDate];
    else
        _syncFullValueLabel.text    = @"";

    
    MF_COCOA_RELEASE(formatter);
}




#pragma mark - initialization and memory management
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
        self.title=NSLocalizedString(@"Settings",
                                     @"settings");
    }
    return self;
}

- (void)viewDidLoad
{
    // LOG
    DLog(@" -> begin");
    
    [super viewDidLoad];
    
    
    [ self configureUI ];
    [ self localize ];
    
    [ self setVersionValues ];
    [ self setSyncValues ];
    
    
    // LOG
    DLog(@" -> end");
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) dealloc
{
    
    DLog(@"-> Deallocating");
    
    MF_COCOA_RELEASE(_lblApplicationDetails);

    MF_COCOA_RELEASE(_versionTitleLabel);
    MF_COCOA_RELEASE(_versionValueLabel);
    MF_COCOA_RELEASE(_versionUpdateButton);
    
    MF_COCOA_RELEASE(_syncTitleLabel);
    MF_COCOA_RELEASE(_syncFullLabel);
    MF_COCOA_RELEASE(_syncFullValueLabel);
    MF_COCOA_RELEASE(_syncInitButton);

    MF_COCOA_RELEASE(_txtvDisclaimer);
    MF_COCOA_RELEASE(_txtvLicence);
    
    self.view   = nil;
    [super dealloc];
}

@end
