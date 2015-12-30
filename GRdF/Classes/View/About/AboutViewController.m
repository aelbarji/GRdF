//
//  AboutViewController.m
//  SavoirEtReussir
//
//  Created by Jean-Philippe BEAUFILS on 27/11/12.
//  Copyright (c) 2012 Onatys. All rights reserved.
//

#import "AboutViewController.h"

@interface AboutViewController ()

@end

@implementation AboutViewController

#pragma mark - UIViewController notifications
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

#pragma mark - private methods
- (void) localize
{
}



- (void) loadWebView
{
    // search for downloaded presentation file, if not found, use resource in bundle
    NSString *docPath = [NSString stringWithString:[[[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                                           NSUserDomainMask,
                                                                                           YES) lastObject]
                                                      stringByAppendingPathComponent:kFolderRoot]
                                                     stringByAppendingPathComponent:[iSR currentLanguage] ]
                                                    stringByAppendingPathComponent:@"about.pdf"]];
    
    NSString *defaultPath = [[NSBundle mainBundle] pathForResource:@"about" ofType:@"pdf"] ;
    NSURL *url;
    
    DLog(@"docPath:%@", docPath);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:docPath])
    {
        url              = [NSURL fileURLWithPath:docPath];
    }
    else
    {
        url             = [NSURL fileURLWithPath:defaultPath];
    }
    
    NSMutableURLRequest *request   = [NSMutableURLRequest requestWithURL:url];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    
    [ _wvAbout  loadRequest:request];
    
    request = nil;
    url = nil;
    
}


#pragma mark - initialization and memory management
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self localize];
    
    [self loadWebView];
    [SRGlobals addStatusBarHeight:_wvAbout];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}


- (void)viewDidUnload {
    [self setWvAbout:nil];
    [super viewDidUnload];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title=NSLocalizedString(@"About",@"About");

//        self.tabBarItem.image = [UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"info_24" ofType: @"png"]];
    }
    return self;
}


- (void)dealloc
{
    [_wvAbout release];
    
    self.view   = nil;
    
    [super dealloc];
}
@end
