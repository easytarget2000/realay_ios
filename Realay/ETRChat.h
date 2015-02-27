//
//  ETRConversation.h
//  Realay
//
//  Created by Michel S on 24.03.14.
//  Copyright (c) 2014 Easy Target. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ETRUser.h"
#import "ETRAction.h"

@interface ETRChat : NSObject

/*
 Database ID
 */
@property (nonatomic) NSInteger chatID;

/*
 Key for reference in dictionaries.
 This string should only contain the database ID.
 */
@property (nonatomic) NSString *dictKey;

/*
 Stores if the chat was opened after new messages were received.
 Used by conversation table to highlight unread chat messages.
 */
@property (nonatomic) BOOL didRead;
 
/*
 For private chats:
 the user in this chat who is not the local user, i.e. the chat partner.
 */
@property (strong, nonatomic) ETRUser  *partner;

/*
 All messages in this chat.
 */
@property (strong, nonatomic) NSMutableArray *messages;

/*
 Time of last message in this chat; used for sorting.
 */
@property (strong, nonatomic) NSDate *lastMsgDate;

/*
 Query the database for an existing chat with a given ID.
 */
+ (ETRChat *)chatWithID:(NSInteger)chatID;

/*
 Start a new chat and query the database for a new ID.
 */
+ (ETRChat *)unknownIDChatWithPartner:(ETRUser *)partner;

/*
 If the chat partner is not known yet, get it from the database.
 */
- (void)queryChatPartner;

@end
