//
//  ETRJSONCoreDataConnection.h
//  Realay
//
//  Created by Michel on 02/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ETRAction;
@class ETRConversation;
@class ETRJSONDictionary;
@class ETRRoom;
@class ETRUser;

extern long const ETRActionPublicUserID;


@interface ETRCoreDataHelper : NSObject

#pragma mark -
#pragma mark General Context Accessories

/**
 
 */
+ (BOOL)saveContext;

#pragma mark -
#pragma mark Actions

/**
 Takes a JSON server response in a Dictionary,
 translates it into an Action Object
 and handles the intent of the Action
 or adds Messages to the CoreData.
 
 Does NOT save the Context.
 */
+ (ETRAction *)addActionFromJSONDictionary:(NSDictionary *)jsonDictionary
                            isInitialQuery:(BOOL)isInitial;
/**
 
 */
+ (void)dispatchPublicMessage:(NSString *)messageContent;

/**
 
 */
+ (void)dispatchMessage:(NSString *)messageContent toRecipient:(ETRUser *)recipient;

/**
 
 */
+ (void)dispatchPublicImageMessage:(UIImage *)image;

/**
 
 */
+ (void)dispatchImageMessage:(UIImage *)image toRecipient:(ETRUser *)recipient;

/**
 
 */
+ (void)queueUserUpdate;

/**
 
 */
+ (void)retrySendingQueuedActions;

/**
 
 */
+ (void)cleanActions;

/**
 
 */
+ (void)addActionToQueue:(ETRAction *)unsentAction;

/**
 
 */
+ (void)removeActionFromQueue:(ETRAction *)sentAction;

/**
 
 */
+ (void)removeUserUpdateActionsFromQueue;

/**
 
 */
+ (ETRAction *)blankOutgoingAction;

/**
 
 */
+ (NSFetchedResultsController *)publicMessagesResultsControllerWithDelegate:(id<NSFetchedResultsControllerDelegate>)delegate
                                                       numberOfLastMessages:(NSUInteger)numberOfLastMessages;

/**
 
 */
+ (NSFetchedResultsController *)messagesResultsControllerForPartner:(ETRUser *)partner
                                               numberOfLastMessages:(NSUInteger)numberOfLastMessages
                                                           delegate:(id<NSFetchedResultsControllerDelegate>)delegate;

#pragma mark -
#pragma mark Conversations

+ (ETRConversation *)conversationWithPartner:(ETRUser *)partner;

+ (void)deleteConversation:(ETRConversation *)conversation;

+ (NSFetchedResultsController *)conversationResulsControllerWithDelegate:(id<NSFetchedResultsControllerDelegate>)delegate;

#pragma mark -
#pragma mark Rooms

+ (NSArray *)rooms;

+ (void)insertRoomFromDictionary:(NSDictionary *)jsonDictionary;

+ (ETRRoom *)roomWithRemoteID:(NSNumber *)remoteID;

+ (NSFetchedResultsController *)roomListResultsController;

#pragma mark -
#pragma mark Users

+ (ETRUser *)insertUserFromDictionary:(NSDictionary *)jsonDictionary;

+ (ETRUser *)userWithRemoteID:(NSNumber *)remoteID
          doLoadIfUnavailable:(BOOL)doLoadIfUnavailable;

+ (ETRUser *)copyUser:(ETRUser *)user;

+ (NSArray *)blockedUsers;

+ (int)numberOfUsersInSessionRoom;

+ (NSFetchedResultsController *)userListResultsControllerWithDelegate:(id<NSFetchedResultsControllerDelegate>)delegate;

+ (NSFetchedResultsController *)blockedUserListControllerWithDelegate:(id<NSFetchedResultsControllerDelegate>)delegate;

@end


@interface NSDictionary (TypesafeJSON)

- (NSString *)stringForKey:(id)key;

- (double)doubleValueForKey:(id)key fallbackValue:(double)fallbackValue;

- (int)intValueForKey:(id)key fallbackValue:(int)fallbackValue;

- (long)longValueForKey:(id)key fallbackValue:(long)fallbackValue;

- (short)shortValueForKey:(id)key fallbackValue:(short)fallbackValue;

@end
