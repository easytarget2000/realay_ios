//
//  ETRDbHandler.h
//  Realay
//
//  Created by Michel S on 18.02.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ETRAction;
@class ETRRoom;
@class ETRUser;
@class ETRImageLoader;


extern NSString * ETRAPIBaseURL;


@interface ETRServerAPIHelper : NSObject

#pragma mark -
#pragma mark Actions

- (void)joinRoomAndShowProgressInLabel:(UILabel *)label
                          progressView:(UIProgressView *)progressView
                     completionHandler:(void(^)(BOOL didSucceed))completionHandler;

+ (void)getActionsAndPerform:(void (^)(id<NSObject>))completionHandler;

+ (void)putAction:(ETRAction *)outgoingAction;

#pragma mark -
#pragma mark Images

+ (void)getImageForLoader:(ETRImageLoader *)imageLoader doLoadHiRes:(BOOL)doLoadHiRes;

+ (void)putImageWithHiResData:(NSData *)hiResData
                    loResData:(NSData *)loResData
            completionHandler:(void (^)(NSNumber * imageID))completionHandler;

+ (void)putImageWithHiResData:(NSData *)hiResData
                    loResData:(NSData *)loResData
                     inAction:(ETRAction *)action;

#pragma mark -
#pragma mark Rooms

/*
 Queries the list of rooms that are inside a given distance radius.
 */
+ (void)updateRoomListWithCompletionHandler:(void(^)(BOOL didReceive))completionHandler;

#pragma mark -
#pragma mark Users

/*
 Registers a new User at the database or retrieves the data
 that matches the combination of the given name and device ID;
 stores the new User object through the Local User Manager when finished
 */
+ (void)loginUserWithName:(NSString *)name completionHandler:(void(^)(ETRUser *))onSuccessBlock;

+ (void)getSessionUsersWithCompletionHandler:(void (^)(BOOL)) handler;

+ (void)getUserWithID:(long)remoteID;

+ (void)sendLocalUserUpdate;

@end
