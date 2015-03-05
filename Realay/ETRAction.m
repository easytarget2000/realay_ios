//
//  Action.m
//  Realay
//
//  Created by Michel on 01/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRAction.h"

#import "ETRRoom.h"
#import "ETRUser.h"
#import "ETRSession.h"

#import "ETRSharedMacros.h"

#define kInfoMsgSenderId -20

#define kActionIDUnknown -66

#define kActionCodePublicMessage 10
#define kActionCodePrivateMessage 11
#define kActionCodePublicPhoto 40
#define kActionCodePrivatePhoto 41

@implementation ETRAction

@dynamic remoteID;
@dynamic sentTime;
@dynamic code;
@dynamic messageContent;
@dynamic sender;
@dynamic recipient;
@dynamic room;
@dynamic isInQueue;

+ (ETRAction *)actionFromJSONDictionary:(NSDictionary *)JSONDict {
    if (!JSONDict) return nil;
    
    long senderID = [[JSONDict objectForKey:@"sn"] longValue];
    if (senderID < 10) return nil;
    
    long timeStamp = [[JSONDict objectForKey:@"t"] longValue];
    if (timeStamp < 1) return nil;
    
    ETRAction *receivedAction = [[ETRAction alloc] init];
    
    [receivedAction setRemoteID:[NSNumber numberWithLong:kActionIDUnknown]];
    // TODO: Set Sender & Receiver attributes.
    [receivedAction setSentTime:[NSDate dateWithTimeIntervalSince1970:timeStamp]];
    [receivedAction setCode:[NSNumber numberWithShort:[[JSONDict objectForKey:@"cd"] shortValue]]];
    
    NSString *content = (NSString *)[JSONDict objectForKey:@"m"];
    if (content && [content length]) [receivedAction setMessageContent:content];
    
    return receivedAction;
}

+ (ETRAction *)outgoingMessage:(NSString *)messageContent toRecipient:(ETRUser *)recipient {
    
    short code;
    if ([recipient isEqual:[[ETRSession sharedManager] publicDummyUser]]) code = kActionCodePublicMessage;
    else code = kActionCodePrivateMessage;
    
    ETRAction *message = [[ETRAction alloc] init];
    
    [message setSender:[[ETRLocalUserManager sharedManager] user]];
    [message setRecipient:recipient];
    [message setSentTime:[NSDate date]];
    [message setMessageContent:messageContent];
    
    return message;
}

#pragma mark -
#pragma mark Helper methods

- (NSString *)sentDateHoursAndMinutes {
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm"];
    
    return [timeFormat stringFromDate:[self sentTime]];
}

- (NSString *)sentDateDayDate {
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"dd MMM"];
    
    return [timeFormat stringFromDate:[self sentTime]];
}

- (BOOL)isPublicMessage {
    short code = [[self code] shortValue];
    return (code == kActionCodePublicMessage) || (code == kActionCodePublicPhoto);
}

- (BOOL)isPhotoMessage {
    short code = [[self code] shortValue];
    return (code == kActionCodePublicPhoto) || (code == kActionCodePrivatePhoto);
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
