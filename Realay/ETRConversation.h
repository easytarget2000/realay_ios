//
//  Conversation.h
//  Realay
//
//  Created by Michel on 01/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ETRUser;

@interface ETRConversation : NSManagedObject

@property (nonatomic, retain) NSNumber * hasUnreadMessage;
@property (nonatomic, retain) ETRUser *partner;

@end
