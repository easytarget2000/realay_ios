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
#import "ETRUIConstants.h"
#import "ETRServerAPIHelper.h"
#import "ETRSessionManager.h"

//static NSString *const joinSegue = @"joinToConversationSegue";

@interface ETRJoinViewController ()

@property (strong, nonatomic) NSThread * joinThread;

@property (atomic) BOOL isCanceled;

@end

@implementation ETRJoinViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[[self navigationItem] backBarButtonItem] setAction:@selector(backButtonPressed:)];
    
    ETRRoom * preparedRoom = [[ETRSessionManager sharedManager] room];
    if (!preparedRoom) {
        [[self navigationController] popToRootViewControllerAnimated:YES];
        NSLog(@"ERROR: No Room prepared in SessionManager. Cancelling join procedure.");
        return;
    }
    
    if (_joinThread) {
        return;
    }
    
    NSString * entering = [NSString stringWithFormat:@"Entering %@...", [preparedRoom title]];
    [[self statusLabel] setText:entering];
    [[self progressView] setProgress:0.1f];
    
    _joinThread = [[NSThread alloc] initWithTarget:self
                                          selector:@selector(startJoinThreadforRoom:)
                                            object:preparedRoom];
    [_joinThread start];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Reset Bar elements that might have been changed during navigation to other View Controllers.
    [[self navigationController] setToolbarHidden:YES];
    [[[self navigationController] navigationBar] setTranslucent:NO];
}

- (void)backButtonPressed:(id)sender {
    if (_joinThread) {
        [_joinThread cancel];
    }
    [[self navigationController] popToRootViewControllerAnimated:YES];
}

- (void)startJoinThreadforRoom:(ETRRoom *)room {
    ETRServerAPIHelper * apiHelper = [[ETRServerAPIHelper alloc] init];

    _isCanceled = NO;
    
    [apiHelper joinRoomAndShowProgressInLabel:_statusLabel
                                          progressView:_progressView
                                     completionHandler:^(BOOL didSucceed) {
                                         [NSThread detachNewThreadSelector:@selector(handleJoinCompletion:)
                                                                  toTarget:self
                                                                withObject:@(didSucceed)];
                                     }];
}

- (void)handleJoinCompletion:(NSNumber *)didSucceed {
    if (_isCanceled) {
        return;
    }
    
    if ([didSucceed boolValue]) {
        [[self statusLabel] setText:@"Done."];
        [[self progressView] setProgress:1.0f];
        [super pushToPublicConversationViewController];
    } else {
        [ETRAlertViewFactory showGeneralErrorAlert];
        [[self navigationController] popToRootViewControllerAnimated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // TODO: Cancel if back/cancel button pressed.
    
    if ([self isMovingFromParentViewController] || [self isBeingDismissed]) {
        _isCanceled = YES;
    }
}

//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    if ([[segue destinationViewController] isKindOfClass:[ETRConversationViewController class]]) {
//        ETRConversationViewController * destination;
//        destination = (ETRConversationViewController *)[segue destinationViewController];
//        [destination setIsPublic:YES];
//    }
//}

@end
