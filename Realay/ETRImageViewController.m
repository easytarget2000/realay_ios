//
//  ETRPictureViewController.m
//  Realay
//
//  Created by Michel S on 08.04.14.
//  Copyright (c) 2014 Easy Target. All rights reserved.
//

#import "ETRImageViewController.h"

#import "ETRLocalUser.h"

@implementation ETRImageViewController

#pragma mark - UIViewController

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self loadImage];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // See if this view is supposed to display the image of the device user.
    if ([self isEditable]) [[self navigationItem] setRightBarButtonItem:[self editButton]];
    else [[self navigationItem] setRightBarButtonItem:nil];
    
    [self loadImage];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - Other

- (void)loadImage {
    CGRect imageFrame = self.imageView.frame;
    
    [[self imageView] setImage:[self image]];
    
    imageFrame.size.width = self.view.frame.size.width;
    imageFrame.size.height = imageFrame.size.width;
    
//    if ([self interfaceOrientation] == UIInterfaceOrientationPortrait) {
//        
//        
//    } else {
//        imageFrame.size.height = self.view.frame.size.height;
//        imageFrame.size.width = imageFrame.size.height;
//    }
    
    [[self imageView] setFrame:imageFrame];

}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UIImagePickerControllerDelegate

- (IBAction)editButtonPressed:(id)sender {
    
    if (![self isEditable]) return;
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    [picker setAllowsEditing:YES];
    [picker setDelegate:self];
    [self presentViewController:picker animated:YES completion:nil];
    
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {

    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!image) image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    [self dismissViewControllerAnimated:YES completion:nil];

    [[self imageView] setImage:image];
    [[ETRLocalUser sharedLocalUser] updateImage:image];
}

@end
