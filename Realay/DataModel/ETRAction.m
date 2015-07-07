//
//  Action.m
//  Realay
//
//  Created by Michel on 01/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRAction.h"

#import "ETRLocalUserManager.h"
#import "ETRFormatter.h"
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

#pragma mark -
#pragma mark NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: %@ to %@ at %@: %@, %@",
            [self remoteID],
            [[self sender] name],
            [[self recipient] name],
            [self sentDate],
            [self code],
            [self messageContent]];
}

#pragma mark -
#pragma mark Derived Values

@synthesize imageID = _imageID;

- (NSString *)shortDescription {
    NSString * sender = [[self sender] name];
    NSString * time = [ETRFormatter formattedDate:[self sentDate]];
    return [NSString stringWithFormat:@"%@, %@, %@", sender, time, [self messageContent]];
}

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

- (NSString *)readableMessageContent {
    if ([self isPhotoMessage]) {
        return NSLocalizedString(@"Picture", @"Photo Message");
    } else {
        return [self messageContent];
    }
}

@end
