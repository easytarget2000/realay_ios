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
@class ETRRoom;
@class ETRUser;

@interface ETRCoreDataHelper : NSObject

+ (ETRCoreDataHelper *)helper;

- (void)insertRoomFromDictionary:(NSDictionary *)JSONDictionary;

- (ETRUser *)insertUserFromDictionary:(ETRJSONDictionary *)JSONDictionary;

- (NSFetchedResultsController *)roomListResultsControllerWithDelegate:(id<NSFetchedResultsControllerDelegate>) delegate;

- (ETRRoom *)roomWithRemoteID:(long)remoteID;

- (ETRUser *)userWithRemoteID:(long)remoteID;

@end

@interface NSDictionary (TypesafeJSON)

- (NSString *)stringForKey:(id)key;
- (long)longValueForKey:(id)key withFallbackValue:(long)fallbackValue;
- (short)shortValueForKey:(id)key withFallbackValue:(short)fallbackValue;

@end
