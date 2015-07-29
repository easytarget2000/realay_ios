//
//  ETRConversation.m
//  Realay
//
//  Created by Michel on 25/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRCoreDataHelper.h"
#import "ETRConversation.h"
#import "ETRAction.h"
#import "ETRRoom.h"
#import "ETRUser.h"


@implementation ETRConversation

@dynamic hasUnreadMessage;
@dynamic lastMessage;
@dynamic partner;
@dynamic inRoom;

- (void)updateLastMessage:(ETRAction *)message {
    if (![self lastMessage]) {
        [self setLastMessage:message];
//        [ETRCoreDataHelper saveContext];
        return;
    }
    
    NSComparisonResult dateComparison;
    dateComparison = [[[self lastMessage] sentDate] compare:[message sentDate]];
    if (dateComparison == NSOrderedAscending) {
        [self setLastMessage:message];
        [ETRCoreDataHelper saveContext];
    }
}

@end
