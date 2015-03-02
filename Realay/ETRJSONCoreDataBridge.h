//
//  ETRJSONCoreDataConnection.h
//  Realay
//
//  Created by Michel on 02/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface ETRJSONCoreDataBridge : NSObject

+ (ETRJSONCoreDataBridge *)coreDataBridge;

- (void)insertRoomFromDictionary:(NSDictionary *)JSONDict;

- (NSFetchedResultsController *)roomListResultsControllerWithDelegate:(id<NSFetchedResultsControllerDelegate>) delegate;

@end
