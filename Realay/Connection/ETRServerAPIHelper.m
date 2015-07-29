//
//  ETRDbHandler.m
//  Realay
//
//  Created by Michel S on 18.02.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRServerAPIHelper.h"

#import "ETRAction.h"
#import "ETRActionManager.h"
#import "ETRBouncer.h"
//#import "ETRImageConnectionHandler.h"
#import "ETRImageEditor.h"
#import "ETRImageLoader.h"
#import "ETRImageView.h"
#import "ETRMediaViewController.h"
#import "ETRCoreDataHelper.h"
#import "ETRLocalUserManager.h"
#import "ETRLocationManager.h"
#import "ETRDefaultsHelper.h"
#import "ETRReachabilityManager.h"
#import "ETRRoom.h"
#import "ETRSessionManager.h"
#import "ETRUIConstants.h"
#import "ETRUser.h"


static NSTimeInterval const ETRIntervalAPITimeOut = 20.0;

static short const ETRRadiusDefaultKm = 20;

NSString * ETRAPIBaseURL = @"http://rldb.easy-target.org/";

static NSString *const ETRAPIStatusKey = @"st";

static NSString *const ETRAPIParamAuth = @"device_id";

static NSString *const ETRAPIParamSender = @"sender";

static NSString *const ETRAPIParamSession = @"session";

static NSString *const ETRJoinRoomAPICall = @"do_join_room";

static NSString *const ETRJoinRoomSuccessStatus = @"IUJ_YES";

static NSString *const ETRGetActionsAPICall = @"get_actions";

static NSString *const ETRGetActionsSuccessStatus = @"AS_YES";

static NSString *const ETRGetActionsObjectTag = @"as";

static NSString *const ETRGetLastActionIDAPICall = @"get_last_action_id";

static NSString *const ETRGetLastActionIDSuccessStatus = @"GLA_YES";

static NSString *const ETRGetActionIDObjectTag = @"a";

static NSString *const ETRPutActionAPICall = @"put_action";

static NSString *const ETRAPIParamRecipient = @"recipient";

static NSString *const ETRAPIParamCode = @"code";

static NSString *const ETRAPIParamTime = @"time";

static NSString *const ETRPutActionSuccessStatus = @"INA_YES";

static NSString *const ETRPutMessageSuccessStatus = @"INM_YES";

static NSString *const ETRGetImageAPICall = @"get_image";

static NSString *const ETRPutImageAPICall = @"put_image";

static NSString *const ETRPutImageActionSuccessStatus = @"IIA_YES";

static NSString *const ETRPutUserImageSuccessStatus = @"IIU_YES";

static NSString *const ETRPutRoomImageSuccessStatus = @"IIR_YES";

static NSString *const ETRGetRoomsAPICall = @"get_rooms";

static NSString *const ETRGetRoomsSuccessStatus = @"RS_YES";

static NSString *const ETRDoUpdateUserAPICall = @"do_update_user";

static NSString *const ETRDoUpdateUserSuccessStatus = @"UU_YES";

static NSString *const ETRGetUserAPICall = @"get_user";

static NSString *const ETRUserObjectTag = @"user";

static NSString *const ETRGetUserSuccessStatus = @"SU_YES";

static NSString *const ETRGetLocalUserAPICall = @"get_local_user";

static NSString *const ETRGetSessionUsersAPICall = @"get_session_users";

static NSString *const ETRSessionUsersSuccessStatus = @"UIR_YES";

static NSString *const ETRUserListObjectTag = @"us";

static NSString *const ETRMultiPartBoundary = @"0xRhTmLbOuNdArY";

static NSString *const ETRMultiPartBoundaryReturned = @"\r\n--0xRhTmLbOuNdArY\r\n";

static NSMutableArray *connections;


@interface ETRServerAPIHelper ()

@property (strong, nonatomic) UILabel * progressLabel;

@property (strong, nonatomic) NSTimer * timer;

@property (strong, nonatomic) void (^handler)(id<NSObject>);

@property (nonatomic) BOOL didTimeOut;

@end


@implementation ETRServerAPIHelper

#pragma mark -
#pragma mark Actions

+ (void)joinRoomAndShowProgressInLabel:(UILabel *)label
                     completionHandler:(void(^)(BOOL didSucceed))completionHandler {

    NSDictionary * authParams = [ETRServerAPIHelper sessionAuthDictionary];
    if (!authParams) {
        completionHandler(NO);
        return;
    }
    
    // Prepare the block that will be called at the end.
    void (^getlastActionIDCompletionHandler) (long) = ^(long lastActionID) {
        if ([[NSThread currentThread] isCancelled]) {
            [NSThread exit];
        } else {
            if (lastActionID > 100L) {
                completionHandler([[ETRSessionManager sharedManager] startSession]);
                [[ETRActionManager sharedManager] ackknowledgeActionID:lastActionID];
            } else {
                completionHandler(NO);
            }
        }
    };
    
    void (^getMessagesCompletionHandler) (id<NSObject>) = ^(id<NSObject> receivedObject) {
        if ([[NSThread currentThread] isCancelled]) {
            [NSThread exit];
            return;
        }
        
        if (!receivedObject) {
            completionHandler(NO);
            return;
        }
        
        if ([receivedObject isKindOfClass:[NSArray class]]) {
            NSArray *jsonActions = (NSArray *) receivedObject;
            for (NSObject *jsonAction in jsonActions) {
                if ([jsonAction isKindOfClass:[NSDictionary class]]) {
                    dispatch_async(
                                   dispatch_get_main_queue(),
                                   ^{
                                       [ETRCoreDataHelper addActionFromJSONDictionary:(NSDictionary *)jsonAction
                                                                       isInitialQuery:YES];
                                   });
                }
            }
            dispatch_async(
                           dispatch_get_main_queue(),
                           ^{
                               [ETRCoreDataHelper saveContext];
                           });
        }
        
        [ETRServerAPIHelper getLastActionIDAndPerform:getlastActionIDCompletionHandler];
    };
    
    // Prepare the block that will be called at at the end of getting the User list.
    // This block starts the message loading.
    void (^getUsersCompletionHandler) (BOOL) = ^(BOOL didSucceed) {
        if ([[NSThread currentThread] isCancelled]) {
            [NSThread exit];
            return;
        }
        
        if (!didSucceed) {
            completionHandler(NO);
        } else {
            // Update the UI to show the upcoming step.
            [ETRServerAPIHelper setText:@"Loading messages..." inProgressLabel:label];
            [ETRServerAPIHelper getActionsAndPing:NO completion:getMessagesCompletionHandler];
        }
    };
    
    // Prepare the first block that will be called at the end of inserting the User into the Room.
    // This block starts loading the User list.
    void (^joinBlock) (id<NSObject>) = ^(id<NSObject> receivedObject) {
        if ([[NSThread currentThread] isCancelled]) {
            [NSThread exit];
            return;
        }
        
        // Fetch a boolean from the received Object to see if the request did succeed.
        if (receivedObject && [receivedObject isKindOfClass:[NSNumber class]]) {
            NSNumber * didSucceed = (NSNumber *) receivedObject;
            if ([didSucceed boolValue]) {
                // Update the UI to show the upcoming step.
                [ETRServerAPIHelper setText:@"Loading Users..." inProgressLabel:label];
                [ETRServerAPIHelper getSessionUsersWithCompletionHandler:getUsersCompletionHandler];
                return;
            }
        }
        
        completionHandler(NO);
    };
    
    NSMutableDictionary * joinParams = [NSMutableDictionary dictionaryWithDictionary:authParams];
    [joinParams setObject:[ETRDefaultsHelper authID] forKey:ETRAPIParamAuth];
    
    dispatch_async(
                   dispatch_get_main_queue(),
                   ^{
                       [ETRCoreDataHelper cleanActions];
                   });
    
    [ETRServerAPIHelper performAPICall:ETRJoinRoomAPICall
                                withID:ETRJoinRoomAPICall
                             paramDict:joinParams
                         successStatus:ETRJoinRoomSuccessStatus
                             objectTag:nil
                     completionHandler:joinBlock];
}

+ (void)setText:(NSString *)text inProgressLabel:(UILabel *)label {
    dispatch_async(
                   dispatch_get_main_queue(),
                   ^{
                       if (text && label) {
                           [label setText:text];
                       }
                   });

}

+ (void)getLastActionIDAndPerform:(void (^)(long))completionHandler {
    NSDictionary * authDict = [ETRServerAPIHelper sessionAuthDictionary];
    if (!authDict) {
        completionHandler(-8);
        return;
    }
    
    [ETRServerAPIHelper performAPICall:ETRGetLastActionIDAPICall
                                withID:ETRGetLastActionIDAPICall
                             paramDict:authDict
                         successStatus:ETRGetLastActionIDSuccessStatus
                             objectTag:ETRGetActionIDObjectTag
                     completionHandler:^(id<NSObject> receivedObject) {
                         if (receivedObject && [receivedObject isKindOfClass:[NSString class]]) {
                             NSString * lastActionID = (NSString *)receivedObject;
                             completionHandler((long) [lastActionID longLongValue]);
                         } else {
                             completionHandler(-9);
                         }
                     }];
}

+ (void)getActionsAndPing:(BOOL)doSendPing completion:(void (^)(id<NSObject>))completionHandler {
    
    NSDictionary * authDict = [ETRServerAPIHelper sessionAuthDictionary];
    if (!authDict) {
        return;
    }
    
    NSMutableDictionary * paramDict = [NSMutableDictionary dictionaryWithDictionary:authDict];
    
    ETRActionManager * actionMan = [ETRActionManager sharedManager];
    
    long lastActionID = [actionMan lastActionID];
    
    if (lastActionID < 100L) {
        // This query is the initial one, only relevant messages are queried.
        [paramDict setObject:@"1" forKey:@"initial"];
    } else {
        [paramDict setObject:[NSString stringWithFormat:@"%ld", lastActionID] forKey:@"last"];
    }
    
    if (doSendPing) {
        [paramDict setObject:@"1" forKey:@"ping"];
    }
    
    NSArray * blockedUsers = [ETRCoreDataHelper blockedUsers];
    if ([blockedUsers count]) {
        // If Users have been blocked, add a coma-separated parameter to the API call.
        NSMutableString * blockedUserIDs = [NSMutableString string];
        for (ETRUser * smug in blockedUsers) {
            if ([blockedUserIDs length]) {
                [blockedUserIDs appendString:@","];
            }
            [blockedUserIDs appendString:[[smug remoteID] stringValue]];
        }
        [paramDict setObject:blockedUserIDs forKey:@"blocked"];
    }
    
    [ETRServerAPIHelper performAPICall:ETRGetActionsAPICall
                                withID:ETRGetActionsAPICall
                             paramDict:paramDict
                         successStatus:ETRGetActionsSuccessStatus
                             objectTag:ETRGetActionsObjectTag
                     completionHandler:completionHandler];
}


+ (void)putAction:(ETRAction *)outgoingAction {
    if (!outgoingAction) {
        return;
    }
    
    NSDictionary * authDict = [ETRServerAPIHelper sessionAuthDictionary];
    NSMutableDictionary * paramDict = [NSMutableDictionary dictionaryWithDictionary:authDict];
    
    long recipientID;
    if ([outgoingAction isPublicAction]) {
        recipientID = ETRActionPublicUserID;
    } else if ([outgoingAction recipient]) {
        recipientID = [[[outgoingAction recipient] remoteID] longValue];
    } else {
#ifdef DEBUG
        NSLog(@"ERROR: Could not determine Recipient ID for outgoing Action.");
#endif
        return;
    }
    
    long timestamp = [[outgoingAction sentDate] timeIntervalSince1970];
    
    [paramDict setObject:[NSString stringWithFormat:@"%ld", recipientID] forKey:@"recipient"];
    [paramDict setObject:[NSString stringWithFormat:@"%@", [outgoingAction code]] forKey:@"code"];
    [paramDict setObject:[NSString stringWithFormat:@"%ld", timestamp] forKey:@"time"];
    
    NSString * successStatus;
    if ([outgoingAction isValidMessage]) {
        [paramDict setObject:[outgoingAction messageContent] forKey:@"message"];
        successStatus = ETRPutMessageSuccessStatus;
    } else {
        successStatus = ETRPutActionSuccessStatus;
    }
    
    [ETRServerAPIHelper performAPICall:ETRPutActionAPICall
                                withID:[outgoingAction description]
                             paramDict:paramDict
                         successStatus:successStatus
                             objectTag:nil
                     completionHandler:^(id<NSObject> receivedObject) {
                         
                         if ([receivedObject isKindOfClass:[NSNumber class]]) {
                             NSNumber *didSucceed = (NSNumber *)receivedObject;
                             if ([didSucceed boolValue]) {
#ifdef DEBUG
                                 NSLog(@"Did successfully send Action: %@", outgoingAction);
#endif
                                 [ETRCoreDataHelper removeActionFromQueue:outgoingAction];
                                 return;
                             }
                         }
#ifdef DEBUG
                         NSLog(@"Could not send Action: %@", outgoingAction);
#endif
                         [ETRCoreDataHelper addActionToQueue:outgoingAction];
                     }];
}

+ (void)endSession {
    ETRAction * exitAction = [ETRCoreDataHelper blankOutgoingAction];
    if (!exitAction) {
        return;
    }
    [exitAction setCode:@(ETRActionCodeUserQuit)];
    [ETRServerAPIHelper putAction:exitAction];
}

#pragma mark -
#pragma mark Images

+ (void)getImageForLoader:(ETRImageLoader *)imageLoader
              doLoadHiRes:(BOOL)doLoadHiRes
                 doAdjust:(BOOL)doAdjust {
    if (!imageLoader) {
        return;
    }
    
    ETRChatObject *chatObject = [imageLoader chatObject];
    if (!chatObject) return;
    if (![chatObject imageID]) return;
    NSString * fileID = [chatObject imageFileName:doLoadHiRes];
    if ([ETRServerAPIHelper didStartConnection:fileID]) {
        return;
    }
    
    // Prepare the URL to the download script.
    NSString * URLString = [NSString stringWithFormat:@"%@%@", ETRAPIBaseURL, ETRGetImageAPICall];
    NSURL * URL = [NSURL URLWithString:URLString];
    
    // Prepare the POST request.
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:URL];
    
    NSString * bodyString = [NSString stringWithFormat:@"f=%@.jpg", fileID];
    NSData * bodyData = [bodyString dataUsingEncoding:NSASCIIStringEncoding];
    
#ifdef DEBUG
    NSLog(@"API: %@?%@", URLString, bodyString);
#endif

    [request setHTTPBody:[NSMutableData dataWithData:bodyData]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:ETRIntervalAPITimeOut];
    
    ETRServerAPIHelper * instance = [[ETRServerAPIHelper alloc] init];
    [instance setDidTimeOut:NO];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(
                                               NSURLResponse * response,
                                               NSData * data,
                                               NSError * connectionError
                                               ) {
                               [[instance timer] invalidate];
                               if ([instance didTimeOut]) {
                                   return;
                               }
                               
                               [ETRServerAPIHelper didFinishConnection:fileID];
                               if (connectionError || !data) {
                                   NSLog(@"ERROR: loadImageFromUrlString: %@", connectionError);
                                   return;
                               }
                               
                               // Try to build an image from the received data.
                               UIImage * image = [[UIImage alloc] initWithData:data];
                               
                               if (!image) {
                                   return;
                               }
                               
                               ETRChatObject * loaderObject = [imageLoader chatObject];
                               
                               // Display the image and store the image file
                               // and the low-res image inside of the Object.
                               if (doAdjust) {
                                   [ETRImageEditor cropImage:image
                                                   imageName:fileID
                                                 applyToView:[imageLoader targetImageView]];
                               } else if ([imageLoader targetImageView]) {
                                   [[imageLoader targetImageView] setImage:image];
                               }
                               
                               if ([imageLoader activityIndicator]) {
                                   [[imageLoader activityIndicator] stopAnimating];
                                   [[imageLoader activityIndicator] setHidden:YES];
                               }
                               
                               if ([imageLoader navigationController] && [loaderObject isKindOfClass:[ETRAction class]]) {
                                   UIStoryboard * storyboard;
                                   storyboard = [[imageLoader navigationController] storyboard];
                                   ETRMediaViewController * mediaViewController;
                                   mediaViewController = [storyboard instantiateViewControllerWithIdentifier:ETRViewControllerMedia];
                                   
                                   [mediaViewController setMessage:(ETRAction *)loaderObject];
                                   
                                   [[imageLoader navigationController] pushViewController:mediaViewController
                                                                                 animated:YES];
                               }
                               
                               if (!doLoadHiRes && loaderObject) {
                                   [loaderObject setLowResImage:image];
                               }
                               
//                               UIImage * fixedOrientationImage = [UIImage imageWithCGImage:[image CGImage]
//                                                                                     scale:[image scale]
//                                                                               orientation:UIImageOrientationUp];
                               NSData * imageData = UIImageJPEGRepresentation(image, 1.0f);
                               [imageData writeToFile:[loaderObject imageFilePath:doLoadHiRes]
                                                                        atomically:YES];
                           }];
    
    [instance setTimer:[NSTimer scheduledTimerWithTimeInterval: ETRIntervalAPITimeOut
                                                        target: instance
                                                      selector: @selector(cancelURLConnection:)
                                                      userInfo: nil
                                                       repeats: NO]];
}

+ (void)putImageWithHiResData:(NSData *)hiResData
                    loResData:(NSData *)loResData
            completionHandler:(void (^)(NSNumber *))completionHandler {
    // Forward data to all-mighty function.
    [ETRServerAPIHelper putImageWithHiResData:hiResData
                                    loResData:loResData
                                     inAction:nil
                            completionHandler:completionHandler];
}

+ (void)putImageWithHiResData:(NSData *)hiResData
                    loResData:(NSData *)loResData
                     inAction:(ETRAction *)action {
    // Forward data to all-mighty function.
    [ETRServerAPIHelper putImageWithHiResData:hiResData
                                    loResData:loResData
                                     inAction:action
                            completionHandler:^(NSNumber * imageID) {
                                // If the image upload was successful,
                                // a new image ID is given.
                                // If it failed, the temporary image ID stays assigned
                                // and will be reuploaded automatically later on.
                                
                                if ([imageID compare:@(10L)] == NSOrderedDescending && action) {
                                    // Delete the old files, then set the new ID.
                                    [action deleteImageFiles];
                                    [action setImageID:imageID];
                                    [ETRCoreDataHelper saveContext];
                                    
                                    // Store the data in the new files.
                                    [loResData writeToFile:[action imageFilePath:NO]
                                                atomically:YES];
                                    [hiResData writeToFile:[action imageFilePath:YES]
                                                atomically:YES];
                                    
                                    [ETRCoreDataHelper saveContext];
                                }
                            }];
    
    
}

+ (void)putImageWithHiResData:(NSData *)hiResData
                    loResData:(NSData *)loResData
                     inAction:(ETRAction *)action
            completionHandler:(void (^)(NSNumber * imageID))completionHandler {
    
    if (![ETRReachabilityManager isReachable]) {
#ifdef DEBUG
        NSLog(@"WARNING: Reachability is negative.");
#endif
        completionHandler(@(-11L));
        return;
    }
    
    // Prepare the URL to the download script.
    NSString *URLString = [NSString stringWithFormat:@"%@%@", ETRAPIBaseURL, ETRPutImageAPICall];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    // Prepare the POST request.
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"POST"];
    //    [request setTimeoutInterval:kHTTPTimeout];
    [request setURL:URL];
    

    // Header:
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", ETRMultiPartBoundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *bodyData = [NSMutableData data];
    [bodyData appendData:[[NSString stringWithFormat:@"--%@\r\n", ETRMultiPartBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    // The hi-res image file:
    [bodyData appendData:[@"Content-Disposition: form-data; name=\"userfile\"; filename=\"upimg.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [bodyData appendData:[@"Content-Type: image/jpg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [bodyData appendData:hiResData];
    //    [bodyData appendData:[NSData dataWithData:UIImageJPEGRepresentation(image, 0.9f)]];
    [bodyData appendData:[ETRMultiPartBoundaryReturned dataUsingEncoding:NSUTF8StringEncoding]];
    
    // The lo-res image file:
    [bodyData appendData:[@"Content-Disposition: form-data; name=\"userfile_s\"; filename=\"upimgs.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [bodyData appendData:[@"Content-Type: image/jpg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [bodyData appendData:loResData];
    //    [bodyData appendData:[NSData dataWithData:UIImageJPEGRepresentation(smallImage, 0.7f)]];
    [bodyData appendData:[ETRMultiPartBoundaryReturned dataUsingEncoding:NSUTF8StringEncoding]];
    
    // Prepare the additional parameters.
    
    NSMutableDictionary * params = [NSMutableDictionary dictionary];
    [params setObject:[[[[ETRLocalUserManager sharedManager] user] remoteID] stringValue] forKey:ETRAPIParamSender];
    
    NSString * time;
    NSString * successStatus;
    if (action) {
        [params setObject:[[[action room] remoteID] stringValue] forKey:ETRAPIParamSession];
        
        NSString * recipientID;
        if ([action isPublicAction]) {
            recipientID = [NSString stringWithFormat:@"%ld", ETRActionPublicUserID];
        } else {
            recipientID = [[[action recipient] remoteID] stringValue];
        }
        [params setObject:recipientID forKey:ETRAPIParamRecipient];
        
        [params setObject:[[action code] stringValue] forKey:ETRAPIParamCode];
        
        time = [NSString stringWithFormat:@"%ld", (long) [[action sentDate] timeIntervalSince1970]];
        successStatus = ETRPutImageActionSuccessStatus;
    } else {
        // If no Action was given, this API Call is part of a profile picture change.
        
        [params setObject:[ETRDefaultsHelper authID] forKey:ETRAPIParamAuth];
        ETRRoom * sessionRoom = [ETRSessionManager sessionRoom];
        if (sessionRoom) {
            [params setObject:[[sessionRoom remoteID] stringValue] forKey:ETRAPIParamSession];
        }
        time = [NSString stringWithFormat:@"%ld", (long) [[NSDate date] timeIntervalSince1970]];
        successStatus = ETRPutUserImageSuccessStatus;
    }
    [params setObject:time forKey:ETRAPIParamTime];
    
    // TODO: Stream files instead of placing them into one giant Data Object.
    
    for (NSString * param in [params allKeys]) {
        NSString * header = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", param];
        [bodyData appendData:[header dataUsingEncoding:NSUTF8StringEncoding]];
        [bodyData appendData:[[params objectForKey:param] dataUsingEncoding:NSUTF8StringEncoding]];
        [bodyData appendData:[ETRMultiPartBoundaryReturned dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    NSString * end = [NSString stringWithFormat:@"%@--", ETRMultiPartBoundary];
    [bodyData appendData:[end dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:bodyData];
    
    [ETRServerAPIHelper performAPIRequest:request
                                   withID:[loResData description]
                            successStatus:successStatus
                                objectTag:@"i"
                        completionHandler:^(id<NSObject> receivedObject) {
                            if (receivedObject && [receivedObject isKindOfClass:[NSString class]]) {
#ifdef DEBUG
                                NSLog(@"Put image got ID: %@", receivedObject);
#endif
                                NSString * remoteImageID = (NSString *)receivedObject;
                                completionHandler(@((long) [remoteImageID longLongValue]));
                            } else {
#ifdef DEBUG
                                NSLog(@"ERROR: Did not receive an Image ID.");
#endif
                                completionHandler(@(-19));
                            }
                        }];
}

#pragma mark -
#pragma mark Rooms

+ (void)updateRoomListWithCompletionHandler:(void(^)(BOOL didReceive))completionHandler {

    CLLocation *location = [ETRLocationManager location];
    if (!location) {
#ifdef DEBUG
        NSLog(@"WARNING: Not updating Room list because Location is unknown.");
#endif
        completionHandler(NO);
        return;
    }
    
    // Get the current coordinates from the main manager.
    CLLocationCoordinate2D coordinate;
    coordinate = [location coordinate];
    
    NSMutableDictionary * paramDict = [NSMutableDictionary dictionary];
    [paramDict setObject:[NSString stringWithFormat:@"%g", coordinate.latitude] forKey:@"lat"];
    [paramDict setObject:[NSString stringWithFormat:@"%g", coordinate.longitude] forKey:@"lng"];
    [paramDict setObject:[NSString stringWithFormat:@"%d", ETRRadiusDefaultKm] forKey:@"dist"];

    [ETRServerAPIHelper performAPICall:ETRGetRoomsAPICall
                                withID:ETRGetRoomsAPICall
                             paramDict:paramDict
                         successStatus:ETRGetRoomsSuccessStatus
                             objectTag:@"rs"
                     completionHandler:^(NSObject *receivedObject) {
//                         [ETRServerAPIHelper didFinishConnection:connectionId];
                         
                         // Check if an array of rooms was returned by this API call.
                         if (receivedObject && [receivedObject isKindOfClass:[NSArray class]]) {
                             
                             NSArray *jsonRooms = (NSArray *) receivedObject;
                             for (NSObject *jsonRoom in jsonRooms) {
                                 if ([jsonRoom isKindOfClass:[NSDictionary class]]) {
                                     [ETRCoreDataHelper insertRoomFromDictionary:(NSDictionary *) jsonRoom];
                                 }
                             }
                             [ETRCoreDataHelper saveContext];
                             [ETRDefaultsHelper acknowledgeRoomListUpdateAtLocation:location];
                             
                             if (completionHandler) {
                                 completionHandler([jsonRooms count]);
                             }
                         } else if (completionHandler) {
                             completionHandler(NO);
                         }
                     }];
    
    return;
}

#pragma mark -
#pragma mark Users

/*
 Registers a new User at the database or retrieves the data
 that matches the combination of the given name and device ID;
 stores the new User object through the Local User Manager when finished
 */
+ (void)loginUserWithName:(NSString *)name completionHandler:(void(^)(BOOL))onSuccessBlock {
    
    NSMutableDictionary * paramDict = [NSMutableDictionary dictionary];
    [paramDict setObject:name forKey:@"name"];
    [paramDict setObject:[ETRDefaultsHelper authID] forKey:ETRAPIParamAuth];
    [paramDict setObject:@"Send me a RealHey!" forKey:@"status"];
    
    [ETRServerAPIHelper performAPICall:ETRGetLocalUserAPICall
                                withID:ETRGetLocalUserAPICall
                             paramDict:paramDict
                         successStatus:ETRGetUserSuccessStatus
                             objectTag:ETRUserObjectTag
                     completionHandler:^(id<NSObject> receivedObject) {
                         if (receivedObject && [receivedObject isKindOfClass:[NSDictionary class]]) {
                             NSDictionary * jsonDictionary;
                             jsonDictionary = (NSDictionary *) receivedObject;
                             ETRUser * localUser;
                             localUser = [ETRCoreDataHelper insertUserFromDictionary:jsonDictionary];
                             [ETRCoreDataHelper saveContext];
                             
                             if (localUser) {
                                 [[ETRLocalUserManager sharedManager] setUser:localUser];
                                 [[ETRLocalUserManager sharedManager] storeUserDefaults];
                                 onSuccessBlock(YES);
                                 return;
                             }
                         }
                         
                         onSuccessBlock(NO);
                         
                     }];
}

+ (void)dispatchUserUpdate {
    ETRUser * localUser = [[ETRLocalUserManager sharedManager] user];
    if (!localUser) {
        return;
    }
    
    NSMutableDictionary * paramDict = [ETRServerAPIHelper sessionAuthDictionary];
    [paramDict setObject:[[localUser remoteID] stringValue] forKey:ETRAPIParamSender];
    [paramDict setObject:[ETRDefaultsHelper authID] forKey:ETRAPIParamAuth];
    [paramDict setObject:[localUser name] forKey:@"name"];
    
    if ([localUser status]) {
      [paramDict setObject:[localUser status] forKey:@"status"];
    }
    if ([localUser mail]) {
        [paramDict setObject:[localUser mail] forKey:@"email"];
    }
    if ([localUser phone]) {
        [paramDict setObject:[localUser phone] forKey:@"phone"];
    }
    if ([localUser website]) {
        [paramDict setObject:[localUser website] forKey:@"website"];
    }
    if ([localUser facebook]) {
        [paramDict setObject:[localUser facebook] forKey:@"website"];
    }
    if ([localUser instagram]) {
        [paramDict setObject:[localUser instagram] forKey:@"ig"];
    }
    if ([localUser twitter]) {
        [paramDict setObject:[localUser twitter] forKey:@"twitter"];
    }
    
    [ETRServerAPIHelper performAPICall:ETRDoUpdateUserAPICall
                                withID:ETRDoUpdateUserAPICall
                             paramDict:paramDict
                         successStatus:ETRDoUpdateUserSuccessStatus
                             objectTag:nil
                     completionHandler:^(id<NSObject> receivedObject) {
                         if (receivedObject && [receivedObject isKindOfClass:[NSNumber class]]) {
                             if ([((NSNumber *) receivedObject) boolValue]) {
                                 [ETRCoreDataHelper removeUserUpdateActionsFromQueue];
#ifdef DEBUG
                                 NSLog(@"Successfully sent User Update.");
#endif
                                 return;
                             }
                         }
                        
                         [ETRCoreDataHelper queueUserUpdate];
                     }];
}



+ (void)getSessionUsersWithCompletionHandler:(void (^)(BOOL)) handler {
    ETRRoom * sessionRoom = [ETRSessionManager sessionRoom];
    if (!sessionRoom) {
        NSLog(@"ERROR: Not in a Session from which to get a list of Users.");
        if (handler) {
            handler(NO);
        }
        return;
    }
    
    NSDictionary * authDict = [ETRServerAPIHelper sessionAuthDictionary];
    
    [ETRServerAPIHelper performAPICall:ETRGetSessionUsersAPICall
                                withID:ETRGetSessionUsersAPICall
                             paramDict:authDict
                         successStatus:ETRSessionUsersSuccessStatus
                             objectTag:ETRUserListObjectTag
                     completionHandler:^(id<NSObject> receivedObject) {
                         
                         // Remove all User relationships in this Room, then add the current ones.
                         
                         if (receivedObject && [receivedObject isKindOfClass:[NSArray class]]) {
                             [sessionRoom setUsers:[NSSet set]];
                             
                             NSArray *jsonUsers = (NSArray *) receivedObject;
                             for (NSObject * jsonUser in jsonUsers) {
                                 if ([jsonUser isKindOfClass:[NSDictionary class]]) {
                                     ETRUser * sessionUser;
                                     sessionUser = [ETRCoreDataHelper insertUserFromDictionary:(NSDictionary *)jsonUser];
                                     if (sessionUser && ![[ETRLocalUserManager sharedManager] isLocalUser:sessionUser]) {
                                         [sessionUser setInRoom:sessionRoom];
                                     }
                                 }
                             }
                             [ETRCoreDataHelper saveContext];
                             
                             if (handler) {
                                 handler(YES);
                             }
                         } else {
                             NSLog(@"ERROR: Could not get the list of Session Users.");
                             if (handler) {
                                 handler(NO);
                             }
                         }
                     }];
}
/**
 Does NOT save Managed Object Context.
 */
+ (void)getUserWithID:(NSNumber *)remoteID {
    if (!remoteID || [remoteID longValue] < 100L) {
        return;
    }
    
    NSDictionary * authParams = [ETRServerAPIHelper sessionAuthDictionary];
    NSMutableDictionary * paramDict = [NSMutableDictionary dictionaryWithDictionary:authParams];
    NSString * remoteIDString = [remoteID stringValue];
    [paramDict setObject:remoteIDString forKey:@"user"];
    
    NSString * connectionID = [NSString stringWithFormat:@"getUser:%@", remoteIDString];
    
    [ETRServerAPIHelper performAPICall:ETRGetUserAPICall
                                withID:connectionID
                             paramDict:paramDict
                         successStatus:ETRGetUserSuccessStatus
                             objectTag:ETRUserObjectTag
                     completionHandler:^(id<NSObject> receivedObject) {
                         if (receivedObject && [receivedObject isKindOfClass:[NSDictionary class]]) {
                             NSDictionary * jsonDictionary;
                             jsonDictionary = (NSDictionary *) receivedObject;
                             [ETRCoreDataHelper insertUserFromDictionary:jsonDictionary];
//                             [ETRCoreDataHelper saveContext];
                         } else {
#ifdef DEBUG
                             NSLog(@"ERROR: Could not find User %@ on the Server.", remoteID);
#endif
                         }
                     }];
}

#pragma mark -
#pragma mark Basic Connection Handling

+ (BOOL)didStartConnection:(NSString *)connectionID {
    if (!connectionID) {
        return NO;
    }
    
    if (!connections) {
        connections = [NSMutableArray array];
    } else if ([connections containsObject:connectionID]) {
#ifdef DEBUG
        NSLog(@"Not performing %@ because the same call has already been started.", connectionID);
#endif
        return YES;
    }
    
    [connections addObject:connectionID];
    return NO;
}

+ (void)didFinishConnection:(NSString *)connectionID {
    if (!connectionID) {
        return;
    }
    
    if (!connections) {
        connections = [NSMutableArray array];
        return;
    } else if ([connections containsObject:connectionID]){
        [connections removeObject:connectionID];
    }
}

+ (void)performAPIRequest:(NSURLRequest *)request
                   withID:(NSString *)connectionID
            successStatus:(NSString *)successStatus
                objectTag:(NSString *)objectTag
        completionHandler:(void (^)(id<NSObject> receivedObject)) handler {
    
    ETRServerAPIHelper * instance = [[ETRServerAPIHelper alloc] init];
    [instance setHandler:handler];
    [instance setDidTimeOut:NO];
    
    if (![ETRReachabilityManager isReachable]) {
#ifdef DEBUG
        NSLog(@"WARNING: Reachability is negative.");
#endif
        instance.handler(@(NO));
        return;
    }
    
    if ([ETRServerAPIHelper didStartConnection:connectionID]) {
        instance.handler(@(NO));
        return;
    }
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data,
                                               NSError *connectionError) {
                               
                               [[instance timer] invalidate];
                               [ETRServerAPIHelper didFinishConnection:connectionID];
                               
                               if ([instance didTimeOut]) {
                                   return;
                               }
                               
                               if (!instance.handler) {
#ifdef DEBUG
                                   NSLog(@"ERROR: No completionHandler given for API call: %@", connectionID);
#endif
                                   return;
                               }
                               
                               if (!connectionError && data) {
                                   [[ETRBouncer sharedManager] acknowledgeConnection];
                                   
                                   NSError * error;
                                   NSDictionary *JSONDict = [NSJSONSerialization JSONObjectWithData:data
                                                                                            options:kNilOptions
                                                                                              error:&error];
                                   if (error) {
#ifdef DEBUG
                                       NSLog(@"ERROR: performApiCall: %@", error);
#endif
                                       instance.handler(nil);
                                       return;
                                   }
                                   
                                   NSString *status = (NSString *)[JSONDict objectForKey:ETRAPIStatusKey];
                                   if (!status) {
#ifdef DEBUG
                                       NSLog(@"ERROR: No Status found in response.");
#endif
                                       instance.handler(nil);
                                       return;
                                   }
                                   
                                   if ([status isEqualToString:successStatus]) {
                                       // The call returned a success status code.
                                       if (!objectTag) {
                                           instance.handler(@(YES));
                                       } else {
                                           id<NSObject> receivedObject = [JSONDict objectForKey:objectTag];
                                           if (!receivedObject) {
                                               instance.handler(@(YES));
                                           } else {
                                               instance.handler(receivedObject);
                                           }
                                       }
                                       
                                       return;
                                   } else {
#ifdef DEBUG
                                       NSLog(@"ERROR: %@", status);
#endif
                                       instance.handler(@(NO));
                                       return;
                                   }
                               }
                               
//                               // Something went wrong.
//                               [[ETRBouncer sharedManager] acknowledgeFailedConnection];
                               
                               // If an Object was expected, return nil.
                               // If a boolean was expected, return NO.
                               if (!objectTag) {
                                   instance.handler(@(NO));
                               } else {
                                   instance.handler(nil);
                               }
                           }];
    
    [instance setTimer:[NSTimer scheduledTimerWithTimeInterval: ETRIntervalAPITimeOut
                                                        target: instance
                                                      selector: @selector(cancelURLConnection:)
                                                      userInfo: nil
                                                       repeats: NO]];
}

+ (void)performAPICall:(NSString *)apiCall
                withID:(NSString *)connectionID
             paramDict:(NSDictionary *)paramDict
         successStatus:(NSString *)successStatus
             objectTag:(NSString *)objectTag
     completionHandler:(void (^)(id<NSObject> receivedObject)) handler {
    
    // Prepare the URL to the give PHP file.
    NSString * URLString = [NSString stringWithFormat:@"%@%@", ETRAPIBaseURL, apiCall];
    NSURL * url = [NSURL URLWithString:
                  [URLString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    
    // Prepare the POST request with the given data string.
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    
    // Go through the NSString:NSString Dictionary and build the "param1=value1&param2=value2..." body.
    NSMutableString * bodyString;
    for (NSString * param in [paramDict allKeys]) {
        if (bodyString) {
            [bodyString appendString:@"&"];
        } else {
            bodyString = [NSMutableString string];
        }
        [bodyString appendString:param];
        [bodyString appendString:@"="];
        
        [bodyString appendString:(NSString *) [paramDict valueForKey:param]];
    }
    
#ifdef DEBUG
    NSLog(@"API: %@?%@", apiCall, bodyString);
#endif
    
    NSData * bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding
                                 allowLossyConversion:YES];
    [request setHTTPBody:bodyData];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:ETRIntervalAPITimeOut];
    
    [ETRServerAPIHelper performAPIRequest:request
                                   withID:connectionID
                            successStatus:successStatus
                                objectTag:objectTag
                        completionHandler:handler];
}

- (void)cancelURLConnection:(NSTimer *)timer {
    _didTimeOut = YES;
    if (_handler) {
        _handler(@(NO));
    }
    NSLog(@"Connection timeout.");
    [_timer invalidate];
}

+ (NSMutableDictionary *)sessionAuthDictionary {
    NSMutableDictionary * authParams = [NSMutableDictionary dictionary];
    ETRRoom * preparedRoom = [ETRSessionManager sessionRoom];
    if (!preparedRoom) {
        return authParams;
    }
    
    NSString * sessionID = [NSString stringWithFormat:@"%ld", [[preparedRoom remoteID] longValue]];
    NSString * senderID = [NSString stringWithFormat:@"%ld", [ETRLocalUserManager userID]];
    
    [authParams setObject:senderID forKey:ETRAPIParamSender];
    [authParams setObject:sessionID forKey:ETRAPIParamSession];
    
    return authParams;
}

@end
