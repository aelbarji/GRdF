//
//  DocumentCell.h
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 23/12/13.
//  Copyright (c) 2013 Onatys. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DocumentCell : UITableViewCell

// labels
@property (retain, nonatomic) IBOutlet UILabel *lblTitle;
@property (retain, nonatomic) IBOutlet UILabel *lblNotes;
@property (retain, nonatomic) IBOutlet UILabel *lblInfos;

// other components
@property (retain, nonatomic) IBOutlet UIImageView *imvThumbnail;

- (void) loadWithInfos:(NSDictionary *) aInfos;

@end
