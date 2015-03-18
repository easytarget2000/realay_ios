//
//  ETRJSONCoreDataConnection.h
//  Realay
//
//  Created by Michel on 02/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ETRJSONDictionary;
@class ETRAction;
@class ETRRoom;
@class ETRUser;

extern long const ETRActionPublicUserID;

@interface ETRCoreDataHelper : NSObject

// TODO: Check JSON Dictionaries for non-optional values to avoid crashes.

//+ (ETRCoreDataHelper *)helper;

+ (BOOL)saveContext;

+ (void)insertRoomFromDictionary:(NSDictionary *)jsonDictionary;

+ (void)handleActionFromDictionary:(NSDictionary *)jsonDictionary;

+ (ETRUser *)insertUserFromDictionary:(NSDictionary *)jsonDictionary;

+ (ETRUser *)copyUser:(ETRUser *)user;

+ (NSFetchedResultsController *)roomListResultsControllerWithDelegate:(id<NSFetchedResultsControllerDelegate>) delegate;

+ (NSFetchedResultsController *)publicMessagesResultsControllerWithDelegage:(id<NSFetchedResultsControllerDelegate>)delegate;

+ (NSFetchedResultsController *)messagesResultsControllerForPartner:(ETRUser *)partner
                                                       withDelegate:(id<NSFetchedResultsControllerDelegate>)delegate;

+ (ETRRoom *)roomWithRemoteID:(long)remoteID;

+ (ETRUser *)userWithRemoteID:(long)remoteID downloadIfUnavailable:(BOOL)doDownload;

+ (void)dispatchPublicMessage:(NSString *)messageContent;

+ (void)dispatchMessage:(NSString *)messageContent toRecipient:(ETRUser *)recipient;

+ (void)addActionToQueue:(ETRAction *)unsentAction;

+ (void)removeActionFromQueue:(ETRAction *)sentAction;

+ (void)clearPublicActions;

@end

@interface NSDictionary (TypesafeJSON)

- (NSString *)stringForKey:(id)key;
- (long)longValueForKey:(id)key withFallbackValue:(long)fallbackValue;
- (short)shortValueForKey:(id)key withFallbackValue:(short)fallbackValue;

@end
