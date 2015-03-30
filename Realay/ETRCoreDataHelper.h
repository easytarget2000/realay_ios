//
//  ETRJSONCoreDataConnection.h
//  Realay
//
//  Created by Michel on 02/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ETRAction;
@class ETRConversation;
@class ETRJSONDictionary;
@class ETRRoom;
@class ETRUser;


extern long const ETRActionPublicUserID;


@interface ETRCoreDataHelper : NSObject

+ (BOOL)saveContext;

#pragma mark -
#pragma mark Actions

+ (void)handleActionFromDictionary:(NSDictionary *)jsonDictionary;

+ (void)dispatchPublicMessage:(NSString *)messageContent;

+ (void)dispatchMessage:(NSString *)messageContent toRecipient:(ETRUser *)recipient;

+ (void)dispatchPublicImageMessage:(UIImage *)image;

+ (void)dispatchImageMessage:(UIImage *)image toRecipient:(ETRUser *)recipient;

+ (void)clearPublicActions;

+ (void)addActionToQueue:(ETRAction *)unsentAction;

+ (void)removeActionFromQueue:(ETRAction *)sentAction;

+ (NSFetchedResultsController *)publicMessagesResultsControllerWithDelegage:(id<NSFetchedResultsControllerDelegate>)delegate;

+ (NSFetchedResultsController *)messagesResultsControllerForPartner:(ETRUser *)partner
                                                       withDelegate:(id<NSFetchedResultsControllerDelegate>)delegate;

#pragma mark -
#pragma mark Conversations

+ (ETRConversation *)conversationWithPartner:(ETRUser *)partner;

+ (NSFetchedResultsController *)conversationResulsControllerWithDelegate:(id<NSFetchedResultsControllerDelegate>)delegate;

#pragma mark -
#pragma mark Rooms

+ (void)insertRoomFromDictionary:(NSDictionary *)jsonDictionary;

+ (ETRRoom *)roomWithRemoteID:(long)remoteID;

+ (NSFetchedResultsController *)roomListResultsController;

#pragma mark -
#pragma mark Users

+ (ETRUser *)insertUserFromDictionary:(NSDictionary *)jsonDictionary;

+ (ETRUser *)userWithRemoteID:(long)remoteID downloadIfUnavailable:(BOOL)doDownload;

+ (ETRUser *)copyUser:(ETRUser *)user;

+ (NSFetchedResultsController *)userListResultsControllerWithDelegate:(id<NSFetchedResultsControllerDelegate>)delegate;

@end


@interface NSDictionary (TypesafeJSON)

- (NSString *)stringForKey:(id)key;
- (long)longValueForKey:(id)key withFallbackValue:(long)fallbackValue;
- (short)shortValueForKey:(id)key withFallbackValue:(short)fallbackValue;

@end
