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
#import "ETRSessionManager.h"
#import "ETRUser.h"

@implementation ETRAction

@dynamic code;
@dynamic isInQueue;
@dynamic messageContent;
@dynamic remoteID;
@dynamic sentDate;
@dynamic recipient;
@dynamic room;
@dynamic sender;
@dynamic conversation;

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

@synthesize imageID = _imageID;

- (BOOL)isPublicAction {
    short code = [[self code] shortValue];
    if (code == ETRActionCodePublicMessage || code == ETRActionCodePublicMedia) {
        return YES;
    } else if (code == ETRActionCodeUserJoin || code == ETRActionCodeUserQuit) {
        return YES;
    } else if (code == ETRActionCodeUserUpdate) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isPrivateMessage {
    if (![self isValidMessage]) {
        return NO;
    } else {
        return ![self isPublicAction];
    }
}

- (BOOL)isPhotoMessage {
    short code = [[self code] shortValue];
    return (code == ETRActionCodePublicMedia) || (code == ETRActionCodePrivateMedia);
}

- (BOOL)isSentAction {
    long senderID = [[[self sender] remoteID] longValue];
    return senderID == [ETRLocalUserManager userID];
}

- (BOOL)isValidMessage {
    short code = [[self code] shortValue];
    
    if (code == ETRActionCodePublicMessage || code == ETRActionCodePrivateMessage) {
        return [[self messageContent] length];
    } else {
        return NO;
    }
}

- (NSNumber *)imageID {
    if (_imageID) {
      return _imageID;
    }
    
    [self setImageID:@((long) [[self messageContent] longLongValue])];
    
    return _imageID;
}

@end
