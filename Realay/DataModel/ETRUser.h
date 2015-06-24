//
//  User.h
//  Realay
//
//  Created by Michel on 01/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRChatObject.h"


@class ETRAction, ETRConversation, ETRRoom;


extern short const ETRUserNameMaxLength;

extern short const ETRUserSocialMaxLength;


@interface ETRUser : ETRChatObject

@property (nonatomic, retain) NSString * facebook;
@property (nonatomic, retain) NSNumber * imageID;
@property (nonatomic, retain) NSString * instagram;
@property (nonatomic, retain) NSString * mail;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSNumber * remoteID;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSString * twitter;
@property (nonatomic, retain) NSString * website;
@property (nonatomic, retain) NSNumber * isBlocked;
@property (nonatomic, retain) ETRConversation *inConversation;
@property (nonatomic, retain) ETRRoom *inRoom;
@property (nonatomic, retain) ETRAction *receivedActions;
@property (nonatomic, retain) ETRAction *sentActions;

- (void)addToAddressBook;

@end
