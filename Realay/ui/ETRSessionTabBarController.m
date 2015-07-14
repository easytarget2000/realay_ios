//
//  ETRSessionTabBarController.m
//  Realay
//
//  Created by Michel on 27/05/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRSessionTabBarController.h"

#import "ETRActionManager.h"
#import "ETRConversationViewController.h"
#import "ETRDetailsViewController.h"
#import "ETRLocalUserManager.h"
#import "ETRRoom.h"
#import "ETRSessionManager.h"


static NSString *const ETRSegueSessionTabsToMap = @"SessionTabsToMap";

static NSString *const ETRSegueSessionTabsToSettings = @"SessionTabsToSettings";


@implementation ETRSessionTabBarController

#pragma mark -
#pragma mark UITabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // The title is the current Room
    // and the back-button TO this View Controller is supposed to be empty.
//    [self setTitle:[[ETRSessionManager sessionRoom] title]];

    NSString * backButtonTitle = NSLocalizedString(@"Users", @"List of Users");
    [[[self navigationItem] backBarButtonItem] setTitle:backButtonTitle];
    
    // Create the Map and Profile BarButtons and place them in the NavigationBar.
    UIImage * mapButtonIcon = [UIImage imageNamed:@"Map"];
    UIBarButtonItem * mapButton = [[UIBarButtonItem alloc] initWithImage:mapButtonIcon
                                                     landscapeImagePhone:mapButtonIcon
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(mapButtonPressed:)];
    UIImage * settingsIcon = [UIImage imageNamed:@"Settings_24pt"];
    UIBarButtonItem * settingsButton = [[UIBarButtonItem alloc] initWithImage:settingsIcon
                                                          landscapeImagePhone:settingsIcon
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(settingsButtonPressed:)];
    
//    NSString * settings = NSLocalizedString(@"Settings", @"Preferences");
//    UIBarButtonItem * settingsButton = [[UIBarButtonItem alloc] initWithTitle:settings
//                                                                        style:UIBarButtonItemStylePlain
//                                                                       target:self
//                                                                       action:@selector(settingsButtonPressed:)];
    
    NSArray * rightBarButtons = [[NSArray alloc] initWithObjects:settingsButton, mapButton, nil];
    [[self navigationItem] setRightBarButtonItems:rightBarButtons];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Reset Bar elements that might have been changed during navigation to other View Controllers.
    [[self navigationController] setToolbarHidden:YES];
    [[[self navigationController] navigationBar] setTranslucent:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[ETRActionManager sharedManager] setForegroundPartnerID:@(-52L)];
}

#pragma mark -
#pragma mark Navigation

- (IBAction)mapButtonPressed:(id)sender {
    [self performSegueWithIdentifier:ETRSegueSessionTabsToMap sender:nil];
}

- (IBAction)settingsButtonPressed:(id)sender {
    [self performSegueWithIdentifier:ETRSegueSessionTabsToSettings sender:nil];
}

@end
