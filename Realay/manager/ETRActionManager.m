//
//  ETRActionManager.m
//  Realay
//
//  Created by Michel on 11/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRActionManager.h"

static long ForegroundPartnerID = -1;

@implementation ETRActionManager

+ (void)setForegroundConversationID:(long)remotePartnerID {
    ForegroundPartnerID = remotePartnerID;
}

@end
