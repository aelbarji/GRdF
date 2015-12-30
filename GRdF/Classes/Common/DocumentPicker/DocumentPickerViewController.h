//
//  DocumentPickerViewController.h
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 25/09/13.
//  Copyright (c) 2013 Onatys. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DocumentPickerViewControllerDelegate;

@interface DocumentPickerViewController : UIViewController
// -- Class properties
@property (assign, nonatomic) id <DocumentPickerViewControllerDelegate> pickerDelegate;

// -- User interface components
@property (retain, nonatomic) IBOutlet UIButton *btnCancel;


@end


@protocol DocumentPickerViewControllerDelegate
- (void) documentPickerController:(DocumentPickerViewController *)    aController
                 didEndWithAction:(NSInteger)                         aAction;

- (void)    documentPickerController:(DocumentPickerViewController *) aController
           documentSelectedWithInfos:(NSDictionary *)                 aDocInfos;


@end