//
//  RLUser.m
//  Realay
//
//  Created by Michel S on 11.12.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import "ETRUser.h"

#import "ETRHTTPHandler.h"
#import "ETRImageLoader.h"
#import "ETRLocalUser.h"
#import "ETRSession.h"

#import "SharedMacros.h"
#define kPHPFindChatPartner @"find_chat_partner.php"
#define kPHPSelectUser @"select_user.php"

@implementation ETRUser

//+ (ETRUser *)dummyPublicChatUser {
//    
//    return [ETRUser userWithID:-11 name:@"Public Chat"];
//
//}

+ (ETRUser *)userWithIDKey:(NSString *)key {
    
    // Build the GET URL String.
    NSString *bodyString = [NSMutableString stringWithFormat:@"user_id=%@", key];
    
    // Get the JSON data and parse it.
    NSDictionary *requestJSON = [ETRHTTPHandler JSONDictionaryFromPHPScript:kPHPSelectUser
                                                                 bodyString:bodyString];
    NSString *statusCode = [requestJSON objectForKey:@"status"];
    NSDictionary *userJsonDict = [requestJSON objectForKey:@"user"];
    
    if (![statusCode isEqualToString:@"SELECT_USER_OK"]) {
        NSLog(@"ERROR: %@", statusCode);
        return nil;
    } else {
        return [self userFromJSONDictionary:userJsonDict];
    }
    
}

+ (ETRUser *)userFromJSONDictionary:(NSDictionary *)JSONDict {
    // This new room object will be added to the return array.
    ETRUser *user = [[ETRUser alloc] init];
    
    // Get the room information from the JSON key array.
    [user setUserID:[[JSONDict objectForKey:@"user_id"] intValue]];
    NSString *key = [NSString stringWithFormat:@"%ld", [user userID]];
    [user setUserKey:key];
    [user setName:(NSString *)[JSONDict objectForKey:@"name"]];
    [user setStatus:(NSString *)[JSONDict objectForKey:@"status"]];
    if ([[user status] length] < 1) [user setStatus:@"Hi!"];
    NSString *imageID = [NSString stringWithFormat:@"u%ld", [user userID]];
    [user setImageID:imageID];
    
    [user refreshImage];
    
    return user;
}

//+ (ETRUser *)userWithID:(NSInteger)userID name:(NSString *)name {
//    ETRUser *user = [[ETRUser alloc] init];
//    
//    [user setUserID:userID];
//    NSString *key = [NSString stringWithFormat:@"%ld", [user userID]];
//    [user setUserKey:key];
//    [user setName:name];
//    
//    return user;
//}

+ (ETRUser *)userPartnerInChat:(NSInteger)chatID {
    
    // Request the user ID of the user that is not me in this chat.
    NSString *bodyString = [NSString stringWithFormat:@"chat_id=%ld&user_id=%ld",
                            chatID, [[ETRLocalUser sharedLocalUser] userID]];
    NSDictionary *requestJSON = [ETRHTTPHandler JSONDictionaryFromPHPScript:kPHPFindChatPartner
                                                                 bodyString:bodyString];
    
    // Parse the received data.
    NSString *statusCode = [requestJSON objectForKey:@"status"];
    NSString *partnerKey;
    if ([statusCode isEqualToString:@"SELECT_PARTNER_ID_OK"]) {
        partnerKey = [requestJSON objectForKey:@"user_id"];
    } else {
        NSLog(@"ERROR: %@", statusCode);
        return nil;
    }
    
    // Get the user from the dictionary of users in this room.
    ETRUser *partner = [[[ETRSession sharedSession] users] objectForKey:partnerKey];
    
    if (!partner) {
        NSLog(@"ERROR: No valid user ID found for this chat partner. %ld - %@",
              chatID, partnerKey);
    }
    
    return partner;
}

#pragma mark - Instance Methods

- (NSComparisonResult)compare:(ETRUser *)otherUser {
    return [[self name] compare:[otherUser name]];
}

- (void)refreshImage {
    // Only download the small preview image of this user for now.
    NSString *smallImageID = [NSString stringWithFormat:@"%@s", [self imageID]];
    [self setSmallImage:[ETRHTTPHandler downloadImageWithID:smallImageID]];
    
    [self setImage:nil];
}

@end
