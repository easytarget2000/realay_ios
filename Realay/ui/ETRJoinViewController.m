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

static NSString *const joinSegue = @"joinToPublicConversationSegue";

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
    
    [ETRServerAPIHelper joinRoom:preparedRoom
             showProgressInLabel:_statusLabel
                    progressView:_progressView
               completionHandler:^(BOOL didSucceed) {
                   if (didSucceed) {
                       [self performSegueWithIdentifier:joinSegue sender:nil];
                   } else {
                       
                   }
    }];
}

- (void)performSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    
}

@end
