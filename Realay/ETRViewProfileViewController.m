
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
#import "ETRImageLoader.h"

#import "ETRSharedMacros.h"

#define kSegueToEditField @"viewProfileToEditFieldSegue"
#define kSegueToViewImage @"viewProfileToViewImageSegue"

@implementation ETRViewProfileViewController

#pragma mark - UIViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_user) {
        [[self navigationController] popViewControllerAnimated:NO];
        NSLog(@"ERROR: View Profile controller has no user object to show.");
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[self nameLabel] setText:[_user name]];
}

@end
