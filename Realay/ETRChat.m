//
//  ETRConversation.m
//  Realay
//
//  Created by Michel S on 24.03.14.
//  Copyright (c) 2014 Easy Target. All rights reserved.
//

#import "ETRChat.h"

#import "ETRSession.h"
#import "ETRHTTPHandler.h"

#define kPHPFindChat        @"find_chat.php"
#define kPHPFindChatPartner @"find_chat_partner.php"

@implementation ETRChat

#pragma mark - Factory Methods

+ (ETRChat *)chatWithID:(NSInteger)chatID {
    ETRChat *chat = [[ETRChat alloc] init];
    
    [chat setChatID:chatID];
    NSString *dictKey = [NSString stringWithFormat:@"%ld", chatID];
    [chat setDictKey:dictKey];
    
    [chat setMessages:[NSMutableArray array]];

    return chat;
}

// Start a new chat and query the database for a new ID.
+ (ETRChat *)unknownIDChatWithPartner:(ETRUser *)partner {

    
    NSString *bodyString = [NSString stringWithFormat:@"user1_id=%ld&user2_id=%ld",
                            [[ETRLocalUser sharedLocalUser] userID],
                            [partner userID]];
    
    // Get the JSON data and parse it.
    NSDictionary *JSONDict = [ETRHTTPHandler JSONDictionaryFromPHPScript:kPHPFindChat
                                                              bodyString:bodyString];
    NSString *statusCode = [JSONDict objectForKey:@"status"];
    NSString *chatID;
    
    // See if a chat was found through SELECT or INSERT and get its ID.
    BOOL foundChat      = [statusCode isEqualToString:@"SELECT_CHAT_OK"];
    BOOL createdChat    = [statusCode isEqualToString:@"INSERT_CHAT_OK"];
    if (foundChat || createdChat) {
        chatID = [JSONDict objectForKey:@"chat_id"];
        
        // Try to get the chat from the dictionary of known chats.
        ETRChat *chat = [[ETRSession sharedSession] chatForKey:chatID];
        
        // If it does not exist yet, create an empty chat with this person.
        if (!chat) {
            chat = [ETRChat chatWithID:[chatID integerValue]];
            [chat setPartner:partner];
        }
        return chat;
    } else {
        NSLog(@"ERROR: %@", statusCode);
        return nil;
    }
    
}

#pragma mark - Instance Methods

- (NSComparisonResult)compare:(ETRChat *)otherChat {
    return [[self lastMsgDate]  compare:[otherChat lastMsgDate]];
}

// If the chat partner is not known yet, get it from the database.
- (void)queryChatPartner {
    
    NSString *bodyString = [NSString stringWithFormat:@"chat_id=%ld&user_id=%ld",
                            [self chatID], [[ETRLocalUser sharedLocalUser] userID]];
    
    // Request the JSON data.
    NSDictionary *requestJSON = [ETRHTTPHandler JSONDictionaryFromPHPScript:kPHPFindChatPartner
                                                                 bodyString:bodyString];
    
    // Parse the received JSON data.
    NSString *statusCode = [requestJSON objectForKey:@"status"];
    if ([statusCode isEqualToString:@"FIND_CHAT_PARTNER_OK"]) {
        
        NSDictionary *JSONUser = [requestJSON objectForKey:@"user"];
        ETRUser *partner = [ETRUser userFromJSONDictionary:JSONUser];
        if (partner) [self setPartner:partner];
        else NSLog(@"ERROR: No partner object found for chat %ld.", [self chatID]);
        
    } else {
        NSLog(@"ERROR: %@", statusCode);
    }
    
}

@end
