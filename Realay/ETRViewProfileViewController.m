
//
//  RLViewProfileViewController.m
//  Realay
//
//  Created by Michel S on 12.12.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import "ETRViewProfileViewController.h"

#import "ETRAlertViewBuilder.h"
#import "ETREditFieldViewController.h"
#import "ETRHTTPHandler.h"
#import "ETRImageViewController.h"
#import "ETRSession.h"

#import "SharedMacros.h"

#define kSegueToEditField @"viewProfileToEditFieldSegue"
#define kSegueToViewImage @"viewProfileToViewImageSegue"

@implementation ETRViewProfileViewController

#pragma mark - UIViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![self user]) {
        [[self navigationController] popViewControllerAnimated:NO];
        NSLog(@"ERROR: View Profile controller has no user object to show.");
    }
}

- (void)viewWillAppear:(BOOL)animated {
    
    if ([self showMyProfile]) {
        _user = [ETRLocalUser sharedLocalUser];
//        [[self tableView] setAllowsSelection:YES];
        [[self statusCell] setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [[self statusCell] setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [[self imageView] setImage:[_user image] forState:UIControlStateNormal];
    } else {
//        [[self tableView] setAllowsSelection:NO];
        [[self statusCell] setAccessoryType:UITableViewCellAccessoryNone];
        [[self statusCell] setAccessoryType:UITableViewCellAccessoryNone];
        [[self imageView] setImage:[_user smallImage] forState:UIControlStateNormal];
    }
    
    if (![[self user] image]) {
        // Start the image download in the background.
        [NSThread detachNewThreadSelector:@selector(threadStartDownloading:)
                                 toTarget:self
                               withObject:nil];
    }
    
    [[self nameLabel] setText:[_user name]];
    [[[self statusCell] textLabel] setText:[_user status]];
}

- (void)threadStartDownloading:(id)data {
    [[self user] setImage:[ETRHTTPHandler downloadImageWithID:[[self user] imageID]]];
}

#pragma mark - Navigation

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 2 && [self showMyProfile]) {
        return 0;
    } else {
        return 1;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSString *attributeKey;
    
    switch ([indexPath section]) {
        case 0:
            attributeKey = kUserDefsUserName;
            break;
        case 1:
            attributeKey = kUserDefsUserStatus;
        default:
            break;
    }
    
    if ([self showMyProfile]) {
        [self performSegueWithIdentifier:kSegueToEditField sender:attributeKey];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        if ([indexPath section] == 2) {
            [ETRAlertViewBuilder showBlockConfirmViewWithDelegate:self];
        }
    }
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:kSegueToEditField]) {

        ETREditFieldViewController *destination = [segue destinationViewController];
        [destination setAttributeKey:sender];

    } else if ([[segue identifier] isEqualToString:kSegueToViewImage]) {
        
        ETRImageViewController *destination = [segue destinationViewController];
        
        [destination setImage:[[self user] image]];
        [destination setIsEditable:[self showMyProfile]];
        [destination setTitle:[[self user] name]];
    }
}

- (IBAction)imageButtonPressed:(id)sender {
    // Only display the larger image if it has already been downloaded.
    if ([[self user] image]) {
        [self performSegueWithIdentifier:kSegueToViewImage sender:self];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[ETRSession sharedSession] blockUser:[self user]];
    }
}

@end
