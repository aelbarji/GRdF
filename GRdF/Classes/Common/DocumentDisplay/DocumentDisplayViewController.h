//
//  DocumentDisplayViewController.h
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 09/09/13.
//  Copyright (c) 2013 Onatys. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DocumentDisplayViewControllerDelegate;


@interface DocumentDisplayViewController : UIViewController
// -- class properties
@property (retain, nonatomic) id <DocumentDisplayViewControllerDelegate> delegate;
@property (retain, nonatomic) NSString              *fileName;

// -- User interface components
@property (retain, nonatomic) IBOutlet UIWebView    *wvDocument;

@property (retain, nonatomic) IBOutlet UILabel      *lblTitle;
@property (retain, nonatomic) IBOutlet UILabel      *lblDescription;


@property (retain, nonatomic) IBOutlet UIButton     *btnClose;
@property (retain, nonatomic) IBOutlet UIButton     *btnPrevious;
@property (retain, nonatomic) IBOutlet UIButton     *btnNext;



@end


@protocol DocumentDisplayViewControllerDelegate

- (void) documentDisplayController:(DocumentDisplayViewController *) aController controllerDidEndWithAction:(int) aAction;


@end
