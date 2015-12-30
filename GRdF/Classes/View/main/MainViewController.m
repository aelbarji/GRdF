//
//  MainViewController.m
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 18/11/2014.
//  Copyright (c) 2014 Onatys. All rights reserved.
//
#import <MapKit/MapKit.h>

// -- definitions
typedef enum {
    GRdFMainViewMode_None = 0,
    GRdFMainViewMode_List,
    GRdFMainViewMode_Map
} GRdFMain_ViewMode;

typedef NSInteger _GRdFMain_ViewMode;

// -- interface
#import "DocumentInterface.h"

// -- UIView controllers
#import "DocumentDisplayViewController.h"
#import "ResultMapViewController.h"
#import "ResultListViewController.h"
#import "SettingsViewController.h"

#import "MainViewController.h"

@interface MainViewController () <UINavigationControllerDelegate,
                                    DocumentDisplayViewControllerDelegate,
                                    ResultListViewControllerDelegate,
                                    ResultMapViewControllerDelegate>
{
    // -- sub controllers
    ResultListViewController        *_resultListController;
    ResultMapViewController         *_resultMapController;
    
    SettingsViewController          *_settingsController;
    
    DocumentDisplayViewController   *_docDetailController;
    
    NSInteger   _currentViewMode;
}

@end

@implementation MainViewController

#pragma mark - user interface actions
- (IBAction) showSettings:(id)sender
{
    DLog(@"-> begin");
    
    if (!_settingsController)
    {
        _settingsController = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController"
                                                                       bundle:nil];
    }
    
    [self.navigationController pushViewController:_settingsController
                                         animated:NO];
    
    DLog(@"-> end");
}

- (IBAction) toggleMode:(UIBarButtonItem *) sender
{
    [self refreshDisplayForMode:(_currentViewMode == GRdFMainViewMode_Map ?
                                 GRdFMainViewMode_List :
                                 GRdFMainViewMode_Map)];
    
    [sender setTitle:NSLocalizedString((_currentViewMode == GRdFMainViewMode_Map ?
                                        @"Mode_List" :
                                        @"Mode_Map"), @"")];
}

#pragma mark - public methods

#pragma mark - UINavigationController delegate notifications
- (void) navigationController:(UINavigationController *)navigationController
        didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (viewController == self)
    {
        MF_COCOA_RELEASE(_docDetailController);
        MF_COCOA_RELEASE(_settingsController);
    }
}


#pragma mark - DocumentDisplayViewController delegate notifications
- (void) documentDisplayController:(DocumentDisplayViewController *)aController
        controllerDidEndWithAction:(int)aAction
{
    [_docDetailController.navigationController popViewControllerAnimated:NO];

    switch (aAction)
    {
        case kControllerAction_Back:
            // ...
            break;
            
        default:
            break;
    }
    
    MF_COCOA_RELEASE(_docDetailController);
}

#pragma mark - ResultListViewController delegate notifications
- (void) resultListViewController:(ResultListViewController *)  aController
           documentSelectedWithId:(NSNumber *)                  aDocumentId
                      andFileName:(NSString *)                  aFileName
{
    [self displayDocumentWithId:aDocumentId
                    andFileName:aFileName];
}

#pragma mark - ResultMapViwController delegate notifications
- (void) resultMapViewController:(ResultMapViewController *)    aController
          documentSelectedWithId:(NSNumber *)                   aDocumentId
                     andFileName:(NSString *)                   aFileName
{
    [self displayDocumentWithId:aDocumentId
                    andFileName:aFileName];
}

- (void) resultMapViewController:(ResultMapViewController *)aController documentsFoundForCurrentRegion:(NSInteger)aNbDocuments
{
    NSString *title = NSLocalizedString(@"Search_MapTitleMask", @"");
    
    NSValue *rCenter = _resultMapController.currentRegionCenterValue;

    if (rCenter)
    {
        CLLocationCoordinate2D center = rCenter.MKCoordinateValue;
        
        title = [title stringByReplacingOccurrencesOfString:@"[lat]"
                                                 withString:[NSString stringWithFormat:@"%.2f", center.latitude ]];
        title = [title stringByReplacingOccurrencesOfString:@"[lon]"
                                                 withString:[NSString stringWithFormat:@"%.2f", center.longitude ]];
    }
    else
    {
        
    }
    
    title = [title stringByReplacingOccurrencesOfString:@"[nb]"
                                             withString:[NSString stringWithFormat:@"%ld", (long)aNbDocuments ]];
    title = [title stringByReplacingOccurrencesOfString:@"(s)"
                                             withString:(aNbDocuments > 0 ? @"s" : @"")];
    
    self.title = title;
    
    [self configureUI:(aNbDocuments > 0)];
    
    rCenter         = nil;
    title           = nil;
}

#pragma mark - private methods
- (void) refreshDisplayForMode:(NSInteger) newMode
{
    DLog(@"-> begin");
    
    if (_currentViewMode != newMode)
    {
        // remove previous controller (if any)
        switch (_currentViewMode)
        {
            case GRdFMainViewMode_List:
            {
                [_resultListController.view removeFromSuperview];
            }    break;
            case GRdFMainViewMode_Map:
            {
                [_resultMapController.view removeFromSuperview];
            }    break;
                
            default:
                break;
        }
        
        // load requested controller
         switch (newMode)
         {
            case GRdFMainViewMode_List:
            {
                if (!_resultListController)
                {
                    _resultListController = [[ResultListViewController alloc] initWithNibName:@"ResultListViewController"
                                                                                       bundle:nil];
                    _resultListController.delegate   = self;
                    _resultListController.view.frame = _viewContainer.bounds;
                    _resultListController.modalPresentationStyle = UIModalPresentationFullScreen;
                }
                // assign result map controller (if any) as datasource delegate
                _resultListController.dataSourceDelegate = (id) _resultMapController;
                
                [_viewContainer addSubview:_resultListController.view];
                [_resultListController reloadData];
            } break;
            case GRdFMainViewMode_Map:
            {
                if (!_resultMapController)
                {
                    _resultMapController = [[ResultMapViewController alloc] initWithNibName:@"ResultMapViewController"
                                                                                     bundle:nil];
                    _resultMapController.delegate   = self;
                    _resultMapController.view.frame = _viewContainer.bounds;
                    _resultMapController.modalPresentationStyle = UIModalPresentationFullScreen;
                }
                
                [_viewContainer addSubview:_resultMapController.view];
            } break;
                
            default:
                break;
        }

        _currentViewMode    = newMode;

    }
    
    
    DLog(@"-> end");
}


- (void) displayDocumentWithId:(NSNumber *) aDocId
                   andFileName:(NSString *) aFileName
{
    // push requested controller
    MF_COCOA_RELEASE(_docDetailController)
    
    _docDetailController = [[DocumentDisplayViewController alloc]
                            initWithNibName:@"DocumentDisplayViewController"
                                     bundle:nil];
    _docDetailController.fileName = aFileName;
    
    [self.navigationController pushViewController:_docDetailController
                                         animated:NO];
}

- (void) localize
{
    DLog(@"-> begin");


    DLog(@"-> end");
}



- (void) configureUI:(BOOL) locationAllowed
{
    DLog(@"-> begin");

    // add "settings" button to navigation bar
    UIImage *imgSettings = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icnSettings_white"
                                                                                            ofType:@"png"]];
    
    UIBarButtonItem *btnSettings = [[UIBarButtonItem alloc] initWithImage:imgSettings
                                                                    style:UIBarButtonItemStyleDone
                                                                   target:self
                                                                   action:@selector(showSettings:)];
    
    self.navigationItem.leftBarButtonItem = btnSettings;
    
    [btnSettings release];

    // add "toggle mode" (map/list) button to navigation bar
    if (locationAllowed)
    {
        UIBarButtonItem *btnToggleMode = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Mode_List" ,
                                                                                                  @"")
                                                                         style:UIBarButtonItemStyleDone
                                                                        target:self
                                                                        action:@selector(toggleMode:)];
        
        self.navigationItem.rightBarButtonItem = btnToggleMode;
        
        [btnToggleMode release];
    }
    else
        self.navigationItem.rightBarButtonItem = nil;
    
    DLog(@"-> end");
}

- (void) cleanMemory
{
    DLog(@"-> begin");
 
    if (_resultListController)
    {
        [_resultListController.view removeFromSuperview];
        MF_COCOA_RELEASE(_resultListController);
    }
    
    if (_resultMapController)
    {
        [_resultMapController.view removeFromSuperview];
        MF_COCOA_RELEASE(_resultMapController);
    }
    
    MF_COCOA_RELEASE(_docDetailController);
    MF_COCOA_RELEASE(_settingsController);
    
    DLog(@"-> end");
}

#pragma mark - initialization and memory management
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _currentViewMode    = GRdFMainViewMode_None;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    BOOL locationAllowed = [iGRdFGps isGpsAllowed];
    
    [self configureUI:locationAllowed];
    [self localize];
    
    locationAllowed = TRUE;
    
    [self refreshDisplayForMode:(locationAllowed ?
                                 GRdFMainViewMode_Map :
                                 GRdFMainViewMode_List)];
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
    
    MF_COCOA_RELEASE(_viewContainer);

    self.view       = nil;
    [super dealloc];
}

@end
