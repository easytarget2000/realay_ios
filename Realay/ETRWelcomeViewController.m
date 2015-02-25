//
//  ETRWelcomeViewController.m
//  Realay
//
//  Created by Michel S on 18.12.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import "ETRWelcomeViewController.h"

#define kSegueToRoomList    @"firstToRoomListSegue"
#define kUserDefKeyNotNew   @"userDefaultsNotNewUs"

@implementation ETRWelcomeViewController

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];

    // If a user id already exists, this app has been started before
    // and the user is configured.   
    if ([[NSUserDefaults standardUserDefaults] integerForKey:kUserDefKeyNotNew]) {
        [self performSegueWithIdentifier:kSegueToRoomList sender:nil];
    }
    
}

- (IBAction)browseButtonPressed:(id)sender {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:1 forKey:kUserDefKeyNotNew];
    [defaults synchronize];
    
    [self performSegueWithIdentifier:kSegueToRoomList sender:nil];
}

@end
