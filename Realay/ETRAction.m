//
//  Action.m
//  Realay
//
//  Created by Michel on 01/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRAction.h"

#import "ETRLocalUserManager.h"
#import "ETRRoom.h"
#import "ETRSession.h"
#import "ETRUser.h"

@implementation ETRAction

@dynamic remoteID;
//@dynamic isPublic;
@dynamic sentDate;
@dynamic code;
@dynamic messageContent;
@dynamic sender;
@dynamic recipient;
@dynamic room;
@dynamic isInQueue;

//+ (ETRAction *)actionFromJSONDictionary:(NSDictionary *)JSONDict {
//    if (!JSONDict) return nil;
//    
//    long senderID = [[JSONDict objectForKey:@"sn"] longValue];
//    if (senderID < 10) return nil;
//    
//    long timeStamp = [[JSONDict objectForKey:@"t"] longValue];
//    if (timeStamp < 1) return nil;
//    
//    ETRAction *receivedAction = [[ETRAction alloc] init];
//    
//    [receivedAction setRemoteID:[NSNumber numberWithLong:kActionIDUnknown]];
//    // TODO: Set Sender & Receiver attributes.
//    [receivedAction setSentDate:[NSDate dateWithTimeIntervalSince1970:timeStamp]];
//    [receivedAction setCode:[NSNumber numberWithShort:[[JSONDict objectForKey:@"cd"] shortValue]]];
//    
//    NSString *content = (NSString *)[JSONDict objectForKey:@"m"];
//    if (content && [content length]) [receivedAction setMessageContent:content];
//    
//    return receivedAction;
//}

#pragma mark -
#pragma mark Derived Values

- (BOOL)isPublicMessage {
    short code = [[self code] shortValue];
    return (code == ETRActionCodePublicMessage) || (code == ETRActionCodePublicMedia);
}

- (BOOL)isPhotoMessage {
    short code = [[self code] shortValue];
    return (code == ETRActionCodePrivateMessage) || (code == ETRActionCodePrivateMedia);
}

- (BOOL)isSentMessage {
    return [[self sender] isEqual:[[ETRLocalUserManager sharedManager] user]];
}

- (void)setImageID:(NSNumber *)imageID {
    [self setImageID:imageID];
}

- (NSNumber *)imageID {
    if ([self imageID]) return [self imageID];
    
    [self setImageID:@((long) [[self messageContent] longLongValue])];
    
    return [self imageID];
}

@end
