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

static NSTimeInterval const ETRTimeIntervalToIdle = 120.0;

static NSTimeInterval const ETRIdleInterval = 40.0;

static NSTimeInterval const ETRMaxIntervalDifference = 2.0;

@interface ETRActionManager ()

//@property (strong, nonatomic) NSInvocation * invocation;           // Invocation for action query timer.

/*
 Last ID of received actions
 */
@property (nonatomic) long lastActionID;

@property (nonatomic) NSTimeInterval queryInterval;

@property (strong, nonatomic) UINavigationController * navCon;               // Navigation Controller for quit-pops

//@property (strong, nonatomic) NSTimer * updateTimer;          // Action query update timer

@property (strong, nonatomic) NSDate * lastActionDate;

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
//    // Prepare the invocation for the timer that queries new actions from the DB.
//    NSMethodSignature * updateSignature = [self methodSignatureForSelector:@selector(queryUpdates)];
//    _invocation = [NSInvocation invocationWithMethodSignature:updateSignature];
//    [_invocation setTarget:self];
//    [_invocation setSelector:@selector(queryUpdates)];

    // Consider the join successful and start the query timer.
    _lastActionDate = [NSDate date];
    [self dispatchQueryTimerWithResetInterval:YES];
    
    return;
}

- (void)endSession {
//    [_updateTimer invalidate];
//    _updateTimer = nil;
    _lastActionID = 50L;
}

- (void)dispatchQueryTimerWithResetInterval:(BOOL)doResetInterval {
    if (doResetInterval || _queryInterval < ETRFastestInterval) {
        _queryInterval = ETRFastestInterval;
        _lastActionDate = [NSDate date];
        NSLog(@"DEBUG: New query Timer interval: %g", _queryInterval);
    } else if (_queryInterval > ETRSlowestInterval) {
        if ([[NSDate date] timeIntervalSinceDate:_lastActionDate] > ETRTimeIntervalToIdle) {
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
    
    // TODO: Track ping times.
    BOOL doPerformPing = YES;
    
    [ETRServerAPIHelper getActionsWithMinID:_lastActionID
                                performPing:doPerformPing
                          completionHandler:^(id<NSObject> receivedObject) {
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

#pragma mark -
#pragma mark Action Processing

- (void)ackActionID:(long)remoteActionID {
    if (_lastActionID < remoteActionID) {
        _lastActionID = remoteActionID;
    }
    _lastActionDate = [NSDate date];
}

- (void)setForegroundPartnerID:(long)foregroundPartnerID {
    _foregroundPartnerID = foregroundPartnerID;
    // TODO: Cancel Notifications from this foreground Conversation.
}

- (void)dispatchNotificationForAction:(ETRAction *)action {
    
}

@end
