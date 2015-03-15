//
//  ETRActionManager.h
//  Realay
//
//  Created by Michel on 11/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ETRAction;

@interface ETRActionManager : NSObject

@property (nonatomic, readonly) long lastActionID;

@property (nonatomic) long foregroundPartnerID;

+ (ETRActionManager *)sharedManager;

- (void)handleReceivedAction:(ETRAction *)receivedAction;

@end
