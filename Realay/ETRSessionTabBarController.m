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
#import "ETRRoom.h"
#import "ETRSessionManager.h"


@interface ETRSessionTabBarController ()

@end


@implementation ETRSessionTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // The title is the current Room
    // and the back-button TO this View Controller is supposed to be empty.
    [self setTitle:[[ETRSessionManager sessionRoom] title]];
    [[[self navigationItem] backBarButtonItem] setTitle:@""];
    
    // Create the Map and Profile BarButtons and place them in the NavigationBar.
    UIImage * mapButtonIcon = [UIImage imageNamed:@"Map"];
    UIBarButtonItem * mapButton = [[UIBarButtonItem alloc] initWithImage:mapButtonIcon
                                                     landscapeImagePhone:mapButtonIcon
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(mapButtonPressed:)];
    UIImage * profileButtonIcon = [UIImage imageNamed:@"Profile"];
    UIBarButtonItem * profileButton = [[UIBarButtonItem alloc] initWithImage:profileButtonIcon
                                                         landscapeImagePhone:profileButtonIcon
                                                                       style:UIBarButtonItemStylePlain target:self
                                                                      action:@selector(profileButtonPressed:)];
    
    NSArray * rightBarButtons = [[NSArray alloc] initWithObjects:profileButton, mapButton, nil];
    [[self navigationItem] setRightBarButtonItems:rightBarButtons];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[ETRActionManager sharedManager] setForegroundPartnerID:@(-52L)];
}

#pragma mark -
#pragma mark Navigation

- (IBAction)mapButtonPressed:(id)sender {
//    [self performSegueWithIdentifier:ETRSegueSessionTabsToMap sender:self];
}

- (IBAction)profileButtonPressed:(id)sender {
//    [self performSegueWithIdentifier:ETRSegueSessionTabsToProfile
//                              sender:[[ETRLocalUserManager sharedManager] user]];
}

//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    id destination = [segue destinationViewController];
//    
//    if ([destination isKindOfClass:[ETRConversationViewController class]]) {
//        if ([sender isKindOfClass:[ETRUser class]]) {
//            ETRConversationViewController *viewController;
//            viewController = (ETRConversationViewController *)destination;
//            [viewController setPartner:sender];
//        }
//        return;
//    }
//    
//    //    if ([destination isKindOfClass:[ETRMapViewController class]]) {
//    //        return;
//    //    }
//    
//    if ([destination isKindOfClass:[ETRDetailsViewController class]]) {
//        if (sender && [sender isKindOfClass:[ETRUser class]]) {
//            ETRDetailsViewController * profileViewController;
//            profileViewController = (ETRDetailsViewController *)destination;
//            [profileViewController setUser:(ETRUser *)sender];
//        }
//    }
//}

@end
