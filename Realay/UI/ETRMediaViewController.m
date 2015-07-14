//
//  ETRMediaViewController.m
//  Realay
//
//  Created by Michel on 29/06/15.
//  Copyright © 2015 Easy Target. All rights reserved.
//

#import "ETRMediaViewController.h"

#import "ETRAction.h"
#import "ETRAlertViewFactory.h"
#import "ETRLocalUserManager.h"
#import "ETRImageLoader.h"
#import "ETRFormatter.h"
#import "ETRUser.h"

@implementation ETRMediaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!_message) {
        return;
    }
    
    if ([[ETRLocalUserManager sharedManager] isLocalUser:[_message sender]]) {
        [[self senderLabel] setText:NSLocalizedString(@"You", @"Local User is Sender")];
    } else {
        [[self senderLabel] setText:[[_message sender] name]];
    }
    
    [[self dateLabel] setText:[ETRFormatter formattedDate:[_message sentDate]]];
    [ETRImageLoader loadImageForObject:_message
                              intoView:[self imageView]
                      placeHolderImage:nil
                           doLoadHiRes:YES
                                doCrop:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Reset Bar elements that might have been changed during navigation to other View Controllers.
    [[[self navigationController] navigationBar] setTranslucent:NO];
    [[self navigationController] setToolbarHidden:YES animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [[self navigationController] popViewControllerAnimated:YES];
}

- (IBAction)saveButtonPressed:(id)sender {
    if ([_message isPhotoMessage]) {
        UIImage * cachedHiResImage;
        cachedHiResImage = [UIImage imageWithContentsOfFile:[_message imageFilePath:YES]];
        
        if (!cachedHiResImage) {
            [ETRAlertViewFactory showGeneralErrorAlert];
        } else {
            UIImageWriteToSavedPhotosAlbum(
                                           cachedHiResImage,
                                           self,
                                           @selector(image:savedInPhotoAlbumWithError:contextInfo:),
                                           nil
                                           );
        }
    }
}

- (void)image:(UIImage *)image savedInPhotoAlbumWithError:(NSError *)error contextInfo:(void *)info {
    if (error) {
        NSLog(@"ERROR: image:savedInPhotoAlbumWithError: %@", error);
        [ETRAlertViewFactory showGeneralErrorAlert];
    } else {
        NSString * title = NSLocalizedString(@"Saved_Image", @"Saved Picture");
        NSString * message = NSLocalizedString(@"File_in_photos", @"Use photos app to open");
        NSString * okButtonTitle = NSLocalizedString(@"OK", @"Ack");
        
        [[[UIAlertView alloc] initWithTitle:title
                                    message:message
                                   delegate:nil
                          cancelButtonTitle:okButtonTitle
                          otherButtonTitles:nil] show];
    }
}

@end
