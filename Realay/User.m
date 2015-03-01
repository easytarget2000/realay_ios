//
//  User.m
//  Realay
//
//  Created by Michel on 01/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "User.h"


@implementation User

@dynamic remoteID;
@dynamic imageID;
@dynamic name;
@dynamic status;
@dynamic mail;
@dynamic phone;
@dynamic website;
@dynamic instagram;
@dynamic facebook;
@dynamic twitter;
@dynamic lastKnownRoom;
@dynamic sentActions;
@dynamic receivedActions;
@dynamic inConversation;

+ (User *)userFromJSONDictionary:(NSDictionary *)JSONDict {
    // This new room object will be added to the return array.
    if (!JSONDict) return nil;
    
    long iden = [[JSONDict objectForKey:@"u"] longValue];
    if (iden < 10) return nil;
    
    NSString *name = (NSString *)[JSONDict objectForKey:@"n"];
    if (!name) return nil;
    else if ([name length] < 1) return nil;
    
    User *user = [[User alloc] init];
    [user setRemoteID:[NSNumber numberWithLong:iden]];
    [user setImageID:[NSNumber numberWithLong:[[JSONDict objectForKey:@"i"] longValue]]];
    [user setName:name];
    [user setStatus:(NSString *)[JSONDict objectForKey:@"s"]];
    [user setMail:(NSString *)[JSONDict objectForKey:@"em"]];
    [user setPhone:(NSString *)[JSONDict objectForKey:@"ph"]];
    [user setWebsite:(NSString *)[JSONDict objectForKey:@"ws"]];
    [user setFacebook:(NSString *)[JSONDict objectForKey:@"fb"]];
    [user setInstagram:(NSString *)[JSONDict objectForKey:@"ig"]];
    [user setTwitter:(NSString *)[JSONDict objectForKey:@"tw"]];
    
    return user;
}

- (NSComparisonResult)compare:(User *)otherUser {
    return [[self name] compare:[otherUser name]];
}

@end
