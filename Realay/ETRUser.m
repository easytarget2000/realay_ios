//
//  User.m
//  Realay
//
//  Created by Michel on 01/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRUser.h"

@implementation ETRUser

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

- (NSComparisonResult)compare:(ETRUser *)otherUser {
    return [[self name] compare:[otherUser name]];
}

@end
