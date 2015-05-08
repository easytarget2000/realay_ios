//
//  ETRActionManager.m
//  Realay
//
//  Created by Michel on 11/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRActionManager.h"

#import "ETRAction.h"
#import "ETRCoreDataHelper.h"
#import "ETRServerAPIHelper.h"
#import "ETRSessionManager.h"


static ETRActionManager *sharedInstance = nil;

static NSTimeInterval const ETRFastestInterval = 2.5;

static NSTimeInterval const ETRSlowestInterval = 10.0;

static CFTimeInterval const ETRTimeIntervalToIdle = 120.0;

static NSTimeInterval const ETRIdleInterval = 40.0;

static NSTimeInterval const ETRMaxIntervalDifference = 2.0;

static CFTimeInterval const ETRPingInterval = 40.0;


@interface ETRActionManager ()

//@property (strong, nonatomic) NSInvocation * invocation;           // Invocation for action query timer.

/*
 Last ID of received actions
 */
@property (nonatomic) long lastActionID;

@property (nonatomic) NSTimeInterval queryInterval;

@property (strong, nonatomic) UINavigationController * navCon;               // Navigation Controller for quit-pops

//@property (strong, nonatomic) NSTimer * updateTimer;          // Action query update timer

@property (nonatomic) CFAbsoluteTime lastActionTime;

@property (nonatomic) CFAbsoluteTime lastPingTime;

@end


@implementation ETRActionManager

+ (void)initialize {
    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        sharedInstance = [[ETRActionManager alloc] init];
    }
}


+ (ETRActionManager *)sharedManager {
    return sharedInstance;
}

#pragma mark -
#pragma mark Session Lifecycle

- (void)startSession {
    // Consider the join successful and start the query timer.
    _lastActionTime = CFAbsoluteTimeGetCurrent();
    [self dispatchQueryTimerWithResetInterval:YES];
    
    return;
}

- (void)endSession {
//    [_updateTimer invalidate];
//    _updateTimer = nil;
    _lastActionID = 0L;
}

- (void)dispatchQueryTimerWithResetInterval:(BOOL)doResetInterval {
    if (doResetInterval || _queryInterval < ETRFastestInterval) {
        _queryInterval = ETRFastestInterval;
        _lastActionTime = CFAbsoluteTimeGetCurrent();
        NSLog(@"DEBUG: New query Timer interval: %g", _queryInterval);
    } else if (_queryInterval > ETRSlowestInterval) {
        if (CFAbsoluteTimeGetCurrent() - _lastActionTime > ETRTimeIntervalToIdle) {
            _queryInterval = ETRIdleInterval;
            NSLog(@"DEBUG: New query Timer interval: %g", _queryInterval);
        }
    } else {
        NSTimeInterval random = drand48();
        _queryInterval += random * ETRMaxIntervalDifference;
        NSLog(@"DEBUG: New query Timer interval: %g", _queryInterval);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:_queryInterval
                                         target:self
                                       selector:@selector(queryUpdates:)
                                       userInfo:nil
                                        repeats:NO];
    });
}

- (void)queryUpdates:(NSTimer *)timer {
    if (![[ETRSessionManager sharedManager] didBeginSession]) {
        NSLog(@"WARNING: Attempted to query Actions outside of Session.");
        return;
    }
    
    [ETRServerAPIHelper getActionsAndPerform:^(id<NSObject> receivedObject) {
        BOOL doResetInterval = NO;
        if ([receivedObject isKindOfClass:[NSArray class]]) {
            NSArray *jsonActions = (NSArray *) receivedObject;
            for (NSObject *jsonAction in jsonActions) {
                if ([jsonAction isKindOfClass:[NSDictionary class]]) {
                    [ETRCoreDataHelper handleActionFromDictionary:(NSDictionary *)jsonAction];
                    doResetInterval = YES;
                }
            }
        }
        
        [self dispatchQueryTimerWithResetInterval:doResetInterval];
    }];
}

- (BOOL)doSendPing {
    return CFAbsoluteTimeGetCurrent() - _lastPingTime > ETRPingInterval;
}

#pragma mark -
#pragma mark Action Processing

- (void)ackknowledgeActionID:(long)remoteActionID {
    if (_lastActionID < remoteActionID) {
        _lastActionID = remoteActionID;
    }
    _lastActionTime = CFAbsoluteTimeGetCurrent();
}

- (void)setForegroundPartnerID:(long)foregroundPartnerID {
    _foregroundPartnerID = foregroundPartnerID;
    // TODO: Cancel Notifications from this foreground Conversation.
}

- (void)dispatchNotificationForAction:(ETRAction *)action {
    
}

@end
