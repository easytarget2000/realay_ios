//
//  ETRConversation.h
//  Realay
//
//  Created by Michel on 25/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ETRAction, ETRRoom, ETRUser;

@interface ETRConversation : NSManagedObject

@property (nonatomic, retain) NSNumber * hasUnreadMessage;
@property (nonatomic, retain) ETRAction *lastMessage;
@property (nonatomic, retain) ETRUser *partner;
@property (nonatomic, retain) ETRRoom *inRoom;

- (void)updateLastMessage:(ETRAction *)message;

@end
