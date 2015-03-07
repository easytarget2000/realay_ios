//
//  ETRDbHandler.h
//  Realay
//
//  Created by Michel S on 18.02.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ETRRoom;
@class ETRUser;
@class ETRImageLoader;

@interface ETRServerAPIHelper : NSObject

// Queries the list of rooms that are inside a given distance radius.
+ (void)updateRoomList;

+ (void)getImageForLoader:(ETRImageLoader *)imageLoader doLoadHiRes:(BOOL)doLoadHiRes;

/*
 Registers a new User at the database or retrieves the data
 that matches the combination of the given name and device ID;
 stores the new User object through the Local User Manager when finished
 */
+ (void)loginUserWithName:(NSString *)name onSuccessBlock:(void(^)(ETRUser *))onSuccessBlock;

+ (void)queryUserListInRoom:(ETRRoom *)room;

@end
