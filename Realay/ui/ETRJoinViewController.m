//
//  ETRJoinViewController.m
//  Realay
//
//  Created by Michel on 10/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRJoinViewController.h"

#import "ETRAlertViewFactory.h"
#import "ETRConversationViewController.h"
#import "ETRRoom.h"
#import "ETRServerAPIHelper.h"
#import "ETRSession.h"

static NSString *const joinSegue = @"joinToConversationSegue";

@interface ETRJoinViewController ()

@property (strong, nonatomic) NSThread *joinThread;

@end

@implementation ETRJoinViewController

- (void)viewDidLoad {
    [[[self navigationItem] backBarButtonItem] setAction:@selector(backButtonPressed:)];
    
    ETRRoom *preparedRoom = [[ETRSession sharedManager] room];
    if (!preparedRoom) {
        [[self navigationController] popToRootViewControllerAnimated:YES];
        NSLog(@"ERROR: No Room prepared in SessionManager. Cancelling join procedure.");
        return;
    }
    
    if (_joinThread) {
        return;
    }
    
    NSString *entering = [NSString stringWithFormat:@"Entering %@...", [preparedRoom title]];
    [[self statusLabel] setText:entering];
    [[self progressView] setProgress:0.1f];
    
    _joinThread = [[NSThread alloc] initWithTarget:self
                                          selector:@selector(startJoinThreadforRoom:)
                                            object:preparedRoom];
    [_joinThread start];
}

- (void)backButtonPressed:(id)sender {
    if (_joinThread) {
        [_joinThread cancel];
    }
    [[self navigationController] popToRootViewControllerAnimated:YES];
}

- (void)startJoinThreadforRoom:(ETRRoom *)room {
    ETRServerAPIHelper *apiHelper = [[ETRServerAPIHelper alloc] init];

    [apiHelper joinRoom:room
    showProgressInLabel:_statusLabel
           progressView:_progressView
      completionHandler:^(BOOL didSucceed) {
          if (didSucceed) {
              [[self statusLabel] setText:@"Done."];
              [[self progressView] setProgress:1.0f];
              [self performSegueWithIdentifier:joinSegue sender:nil];
          } else {
              [ETRAlertViewFactory showGeneralErrorAlert];
              [[self navigationController] popToRootViewControllerAnimated:YES];
          }
      }];
}

- (void)viewWillDisappear:(BOOL)animated {
    // TODO: Cancel if back/cancel button pressed.
    
    if ([self isMovingFromParentViewController] || [self isBeingDismissed]) {
        // Do your stuff here
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue destinationViewController] isKindOfClass:[ETRConversationViewController class]]) {
        ETRConversationViewController *destination;
        destination = (ETRConversationViewController *)[segue destinationViewController];
        [destination setIsPublic:YES];
    }
}

@end
