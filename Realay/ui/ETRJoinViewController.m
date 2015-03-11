//
//  ETRJoinViewController.m
//  Realay
//
//  Created by Michel on 10/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRJoinViewController.h"

#import "ETRRoom.h"
#import "ETRServerAPIHelper.h"
#import "ETRSession.h"

@implementation ETRJoinViewController

- (void)viewDidLoad {
    ETRRoom *preparedRoom = [[ETRSession sharedManager] room];
    if (!preparedRoom) {
        [[self navigationController] popToRootViewControllerAnimated:YES];
        NSLog(@"ERROR: No Room prepared in SessionManager. Cancelling join procedure.");
        return;
    }
    
    NSString *entering = [NSString stringWithFormat:@"Entering %@...", [preparedRoom title]];
    [[self statusLabel] setText:entering];
    [[self progressView] setProgress:0.1f];
    
    
}

@end
