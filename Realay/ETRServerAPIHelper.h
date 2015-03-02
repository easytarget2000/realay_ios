//
//  ETRDbHandler.h
//  Realay
//
//  Created by Michel S on 18.02.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import <Foundation/Foundation.h>



@class User;
@class ETRImageLoader;

@interface ETRServerAPIHelper : NSObject

// Queries the list of rooms that are inside a given distance radius.
+ (void)updateRoomList;

+ (void)getImageLoader:(ETRImageLoader *)imageLoader doLoadHiRes:(BOOL)doLoadHiRes;

/*
 Registers a new User at the database or retrieves the data
 that matches the combination of the given name and device ID;
 stores the new User object through the Local User Manager when finished
 */
+ (void)loginUserWithName:(NSString *)name onSuccessBlock:(void(^)(User *localUser))onSuccessBlock;

@end
