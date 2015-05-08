//
//  ETRPreferenceHelper.h
//  Realay
//
//  Created by Michel on 15/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLLocation;
@class ETRRoom;


@interface ETRDefaultsHelper : NSObject

+ (BOOL)doUseMetricSystem;

+ (NSString *)authID;

#pragma mark -
#pragma mark Location & Room Updates

+ (BOOL)doUpdateRoomListAtLocation:(CLLocation *)location;

+ (void)acknowledgeRoomListUpdateAtLocation:(CLLocation *)location;

+ (CLLocation *)lastUpdateLocation;

#pragma mark -
#pragma mark Session Persistence

+ (ETRRoom *)restoreSession;

+ (void)storeSession:(NSNumber *)sessionID;

+ (void)removeSession;

+ (NSString *)messageInputTextForConversationID:(NSNumber *)conversationID;

+ (void)storeMessageInputText:(NSString *)inputText forConversationID:(NSNumber *)conversationID;

+ (void)removePublicMessageInputTexts;

@end
