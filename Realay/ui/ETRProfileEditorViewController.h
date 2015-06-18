//
//  ETRProfileEditorViewController.h
//  Realay
//
//  Created by Michel on 07/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ETRProfileEditorViewController : UITableViewController
<UIImagePickerControllerDelegate, UINavigationControllerDelegate>

- (IBAction)saveButtonPressed:(id)sender;

- (IBAction)imagePickerButtonPressed:(id)sender;

@end
