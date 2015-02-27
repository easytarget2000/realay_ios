//
//  ETRRoomDetailsViewController.m
//  Realay
//
//  Created by Michel S on 01.03.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRRoomDetailsViewController.h"

#import "ETRLocationManager.h"
#import "ETRAlertViewBuilder.h"

#define kSegueToImage   @"roomDetailsToViewImageSegue"
#define kSegueToNext    @"roomDetailsToPasswordSegue"

@implementation ETRRoomDetailsViewController {
    ETRRoom *room;
}

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Get the room object from the manager.
    room = [[ETRSession sharedSession] room];
    
    // Initialise the GUI elements.
    [[self imageButton] setImage:[room lowResImage] forState:UIControlStateNormal];
    [[self titleLabel] setText:[room title]];

    // Just in case there is a toolbar wanting to be displayed:
    [[self navigationController] setToolbarHidden:YES];
    
    if ([[ETRSession sharedSession] didBeginSession]) {
        [[self navigationItem] setRightBarButtonItem:nil];
    }
    
    // Set the description labels.
    [[self timeLabel] setText:[room timeSpan]];

    // If the room has no address, display the coordinates in a smaller font.
    if ([room address]) {
        [[self addressLabel] setText:[room address]];
    } else {
        [[self addressLabel] setText:[room coordinateString]];
        [[self addressLabel] setFont:[UIFont systemFontOfSize:9.0f]];
    }
    
    [[self amountOfUsersLabel] setText:[room amountOfUsersString]];
    [[self descriptionLabel] setText:[room info]];
    
    // Now this View is the delegate of the relayed location manager.
    [[ETRSession sharedSession] setLocationDelegate:self];
    
    // Make it call the delegate distance methods,so the GUI updates.
    [[ETRSession sharedSession] callLocationManagerDelegates];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[ETRSession sharedSession] setLocationDelegate:nil];
}

#pragma mark - ETRRelayedLocationDelegate

- (void)sessionDidUpdateLocationManager:(ETRLocationManager *)manager {
    
    NSString *distanceLabel, *distanceValue;
    
    // Prepare different distance cells depending on the current location.
    if ([[ETRSession sharedSession] isInRegion]) {
        [[self distanceCell] setBackgroundColor:[UIColor whiteColor]];
        
        //TODO: Localization
        distanceLabel = @"Inside Realay region";
        distanceValue = @" ";
        
    } else {
        [[self distanceCell] setBackgroundColor:[UIColor lightGrayColor]];
        
        //TODO: Localization
        distanceLabel = @"Distance";
        distanceValue = [manager readableDistanceToRoom:room];
    }
    
    // Apply the current values to the labels.
    [[self distanceLabel] setText:distanceLabel];
    [[self distanceValueLabel] setText:distanceValue];
//    [[self accuracyLabel] setText:[manager readableLocationAccuracy]];
//    [[self radiusLabel] setText:[manager readableRadiusOfSessionRoom]];
    
//    [[self tableView] reloadData];
}

#pragma mark - Navigation

- (IBAction)imageButtonPressed:(id)sender {
    // Only display the larger image if it has already been downloaded.

}

- (IBAction)joinButtonPressed:(id)sender {
    // Only perform a join action, if the user did not join yet.
    if (![[ETRSession sharedSession] didBeginSession]) {
        
        // Show the password prompt, if the device location is inside the region.
        if ([[ETRSession sharedSession] isInRegion]) {
            [self performSegueWithIdentifier:kSegueToNext sender:self];
        } else {
            [ETRAlertViewBuilder showOutsideRegionAlertView];
        }
    }
}

@end
