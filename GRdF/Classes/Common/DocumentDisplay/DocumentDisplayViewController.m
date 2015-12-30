//
//  DocumentDisplayViewController.m
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 09/09/13.
//  Copyright (c) 2013 Onatys. All rights reserved.
//

#import "DocumentInterface.h"
#import "DocumentDisplayViewController.h"

@interface DocumentDisplayViewController ()
{
}

@end

@implementation DocumentDisplayViewController

#pragma mark - user interface actions
-(IBAction) close:(id)sender
{
    [self cleanMemory];
    
    if (_delegate)
    {
        [_delegate documentDisplayController:self
                 controllerDidEndWithAction:kControllerAction_Back];
    }
}


#pragma mark - public methods
- (void) loadDocument
{
    if (_fileName)
    {
        NSString *filePath = [DocumentInterface documentPathForFileName:_fileName
                                                            withDefault:nil];
        
        DLog(@"filePath:%@", filePath);
        
        // consider pdf
        NSURL *url              = [NSURL fileURLWithPath:filePath];
        NSURLRequest *request   = [NSURLRequest requestWithURL:url];
        
        
        [ _wvDocument  loadRequest:request];
        
        url                     = nil;
        request                 = nil;
        filePath                = nil;
    }
}




#pragma mark - view controller notifications
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    // in case we allow user to rotate content for better display
    return YES;
}


- (void) localize
{
        // ...
}

- (void) cleanMemory
{
    self.delegate   = nil;
    self.fileName   = nil;
}


#pragma mark - initialization and memory management
- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated
{
    [self loadDocument];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    _lblTitle.layer.cornerRadius        = 8.;
    _lblDescription.layer.cornerRadius  = 8.;

    [self localize];

    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    DLog(@"-> Deallocating");
    
    [self cleanMemory];

    MF_COCOA_RELEASE(_btnClose);
    MF_COCOA_RELEASE(_btnPrevious);
    MF_COCOA_RELEASE(_btnNext);
    MF_COCOA_RELEASE(_lblTitle);
    MF_COCOA_RELEASE(_lblDescription);
    MF_COCOA_RELEASE(_wvDocument);
    
    self.view   = nil;
    [super dealloc];
}
@end
