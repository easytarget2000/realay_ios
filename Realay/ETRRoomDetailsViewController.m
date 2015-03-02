//
//  ETRRoomDetailsViewController.m
//  Realay
//
//  Created by Michel S on 01.03.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRRoomDetailsViewController.h"

#import "ETRLocationHelper.h"
#import "ETRAlertViewBuilder.h"
#import "ETRRoom.h"

#define kSegueToImage   @"roomDetailsToViewImageSegue"
#define kSegueToNext    @"roomDetailsToPasswordSegue"

@interface ETRRoomDetailsViewController()

@property (strong, nonatomic) ETRRoom * room;

@end

@implementation ETRRoomDetailsViewController

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Get the room object from the manager.
    _room = [[ETRSession sharedManager] room];
    if (!_room) {
        NSLog(@"ERROR: Cannot find Session room.");
    }
    
    // Initialise the GUI elements.
    [_imageButton setImage:[_room lowResImage] forState:UIControlStateNormal];
    [_titleLabel setText:[_room title]];

    // Just in case there is a toolbar wanting to be displayed:
    [[self navigationController] setToolbarHidden:YES];
    
    if ([[ETRSession sharedManager] didBeginSession]) {
        [[self navigationItem] setRightBarButtonItem:nil];
    }
    
    // Set the description labels.
    [_timeLabel setText:[_room timeSpan]];
    [_addressLabel setText:[_room address]];
    
    [_userCountLabel setText:[_room userCount]];
    [_descriptionLabel setText:[_room summary]];
    
    // Now this View is the delegate of the relayed location manager.
    [[ETRSession sharedManager] setLocationDelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[ETRSession sharedManager] setLocationDelegate:nil];
}

#pragma mark - ETRRelayedLocationDelegate

- (void)sessionDidUpdateLocationManager:(ETRLocationHelper *)manager {
    
    NSString *distanceLabel, *distanceValue;
    
    // Prepare different distance cells depending on the current location.
    if ([[ETRSession sharedManager] isInRegion]) {
        [[self distanceCell] setBackgroundColor:[UIColor whiteColor]];
        
        //TODO: Localization
        distanceLabel = @"Inside Realay region";
        distanceValue = @" ";
        
    } else {
        [[self distanceCell] setBackgroundColor:[UIColor lightGrayColor]];
        
        //TODO: Localization
        distanceLabel = @"Distance";
        distanceValue = [manager formattedDistanceToRoom:_room];
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
    if (![[ETRSession sharedManager] didBeginSession]) {
        
        // Show the password prompt, if the device location is inside the region.
        if ([[ETRSession sharedManager] isInRegion]) {
            [self performSegueWithIdentifier:kSegueToNext sender:self];
        } else {
            [ETRAlertViewBuilder showOutsideRegionAlertView];
        }
    }
}

@end
