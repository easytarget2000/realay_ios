//
//  ETRReachabilityManager.m
//  Realay
//
//  Created by Michel on 27/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRReachabilityManager.h"

#import "Reachability.h"

#import "ETRCoreDataHelper.h"
#import "ETRDefaultsHelper.h"
#import "ETRLocationManager.h"
#import "ETRServerAPIHelper.h"
#import "ETRSessionManager.h"

@interface ETRReachabilityManager ()

@property (strong, nonatomic) Reachability * reachability;

@end


@implementation ETRReachabilityManager

#pragma mark -
#pragma mark Default Manager

+ (ETRReachabilityManager *)sharedManager {
    static ETRReachabilityManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    
    return _sharedManager;
}

#pragma mark -
#pragma mark Private Initialization

- (id)init {
    self = [super init];
    if (self) {
        // Initialize Reachability & start monitoring.
//        [self setReachability:[Reachability reachabilityWithHostname:ETRAPIBaseURL]];
        [self setReachability:[Reachability reachabilityWithHostname:@"www.google.com"]];
        [[self reachability] startNotifier];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityDidChange:)
                                                     name:kReachabilityChangedNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
    // Stop Notifier
    if (_reachability) {
        [_reachability stopNotifier];
    }
}

#pragma mark -
#pragma mark Class Methods

+ (BOOL)isReachable {
    
    Reachability * reachability = [[ETRReachabilityManager sharedManager] reachability];

    if ([reachability isReachableViaWWAN]) {
        return YES;
    }
    
    if ([reachability isReachableViaWiFi]) {
        return YES;
    }
    
#ifdef DEBUG
    NSLog(@"Device is not reachable via WiFi.");
#endif
    
    return [reachability isReachable];
}

/*!
 * Called by Reachability whenever status changes.
 */
- (void)reachabilityDidChange:(NSNotification *)note {
    if ([ETRReachabilityManager isReachable]) {
        [ETRCoreDataHelper retrySendingQueuedActions];
        
        CLLocation * currentLocation = [ETRLocationManager location];
        if ([ETRDefaultsHelper doUpdateRoomListAtLocation:currentLocation]) {
#ifdef DEBUG
            NSLog(@"%@: Updating Rooms.", [self class]);
#endif
            [ETRServerAPIHelper updateRoomListWithCompletionHandler:nil];
        }
    }
}


@end
