//
//  ETRProfileEditorViewController.h
//  Realay
//
//  Created by Michel on 07/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRBaseViewController.h"

@interface ETRProfileEditorViewController : ETRBaseViewController
<UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)saveButtonPressed:(id)sender;

- (IBAction)imagePickerButtonPressed:(id)sender;

@end
