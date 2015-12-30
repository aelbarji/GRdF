
//  DocumentPickerViewController.m
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 25/09/13.
//  Copyright (c) 2013 Onatys. All rights reserved.
//

#import "DocumentPickerViewController.h"
#import "DocumentCell.h"

#import "DocumentInterface.h"

@interface DocumentPickerViewController () <UITableViewDataSource,
                                            UITableViewDelegate>
{
    NSMutableArray              *_documentIds;
}

@end

@implementation DocumentPickerViewController

#pragma mark - user interface actions
- (IBAction) clicCancel:(id)sender
{
    if (_pickerDelegate)
    {
        [_pickerDelegate documentPickerController:self
                                 didEndWithAction:kControllerAction_Back];
    }
}

#pragma mark - UITableView datasource notifications
// section
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)     tableView:(UITableView *)   tableView
 heightForHeaderInSection:(NSInteger)       section
{
    return 30.;
}


// row
- (NSInteger) tableView:(UITableView *)     tableView
  numberOfRowsInSection:(NSInteger)         section
{
    return _documentIds.count;
}

- (UITableViewCell *) tableView: (UITableView *)tableView
          cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"DocumentCell";
    
    UITableViewCell *cell           = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell==nil)
    {
        NSArray *topLevelObjects    = [[NSBundle mainBundle] loadNibNamed:@"DocumentCell"
                                                                    owner:self
                                                                  options:nil];
        for (id currentObject in topLevelObjects)
        {
            if ([currentObject isKindOfClass:[UITableViewCell class]]){
                cell                =  (DocumentCell *) currentObject;
                break;
            }
        }
    }

    // Configure the cell...
    [((DocumentCell *)cell) loadWithInfos:[_documentIds objectAtIndex:indexPath.row]];
        
    return cell;
}


- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - UITableView delegate notification
- (void)        tableView:(UITableView *)   tableView
  didSelectRowAtIndexPath:(NSIndexPath *)   indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (_pickerDelegate)
    {
        [_pickerDelegate documentPickerController:self
                        documentSelectedWithInfos:[_documentIds objectAtIndex:indexPath.row]];
    }
}


#pragma mark - private methods
- (void) configureCell:(DocumentCell *) aCell
           atIndexPath:(NSIndexPath *) aIndexPath
{
    
}

- (void) localize
{
    self.title                  = NSLocalizedString(@"Documents",
                                                    @"");
    
    [_btnCancel     setTitle    : NSLocalizedString(@"Cancel",@"cancel")
                    forState    : UIControlStateNormal];
    
}



- (void) cleanMemory
{
    DLog(@"-> begin");
    
    MF_COCOA_RELEASE(_documentIds);
    
    _pickerDelegate     = nil;
    
    DLog(@"-> end");

}

#pragma mark - initialization and memory management

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _documentIds = [[NSMutableArray alloc] init];
    
    [self localize];
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

    MF_COCOA_RELEASE(_btnCancel);
    
    self.view = nil;
    [super dealloc];
}

@end
