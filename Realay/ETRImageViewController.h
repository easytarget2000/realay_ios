//
//  ETRPictureViewController.h
//  Realay
//
//  Created by Michel S on 08.04.14.
//  Copyright (c) 2014 Easy Target. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ETRUser.h"

@interface ETRImageViewController : UIViewController
<UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem    *editButton;
@property (weak, nonatomic) IBOutlet UIImageView        *imageView;

@property (nonatomic)           BOOL    isEditable;
@property (strong, nonatomic)   UIImage *image;

- (IBAction)editButtonPressed:(id)sender;

@end
