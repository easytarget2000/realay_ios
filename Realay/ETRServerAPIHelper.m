//
//  ETRDbHandler.m
//  Realay
//
//  Created by Michel S on 18.02.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRServerAPIHelper.h"

#import "ETRAction.h"
#import "ETRImageConnectionHandler.h"
#import "ETRImageEditor.h"
#import "ETRImageLoader.h"
#import "ETRCoreDataHelper.h"
#import "ETRLocalUserManager.h"
#import "ETRLocationManager.h"
#import "ETRRoom.h"
#import "ETRSessionManager.h"
#import "ETRUser.h"

static short const ETRAPITimeOutInterval = 20;

static short const ETRDefaultSearchRadius = 20;

static NSString *const ETRAPIBaseURL = @"http://rldb.easy-target.org/";

static NSString *const ETRAPIStatusKey = @"st";

static NSString *const ETRGetActionsAPICall = @"get_actions";

static NSString *const ETRGetActionsSuccessStatus = @"AS_OK";

static NSString *const ETRGetActionsObjectTag = @"as";

static NSString *const ETRPutActionAPICall = @"put_action";

static NSString *const ETRPutActionSuccessStatus = @"INA_OK";

static NSString *const ETRPutMessageSuccessStatus = @"INM_OK";

static NSString *const ETRGetImageAPICall = @"get_image";

static NSString *const ETRPutImageAPICall = @"put_image";

static NSString *const ETRPutImageSuccessStatus = @"II_OK";

static NSString *const ETRJoinRoomAPICall = @"do_join_room";

static NSString *const ETRJoinRoomSuccessStatus = @"INS_U_OK";

static NSString *const ETRGetRoomsAPICall = @"get_rooms";

static NSString *const ETRGetRoomsSuccessStatus = @"RS_OK";

static NSString *const ETRGetRoomUsersAPICall = @"get_room_users";

static NSString *const ETRRoomUsersSuccessStatus = @"UIR_OK";

static NSString *const ETRUserListObjectTag = @"us";

static NSString *const ETRGetUserAPICall = @"get_user";

static NSString *const ETRUserObjectTag = @"user";

static NSString *const ETRGetUserSuccessStatus = @"SU_OK";

static NSMutableArray *connections;

@interface ETRServerAPIHelper ()

@property (strong, nonatomic) UILabel *progressLabel;

@property (strong, nonatomic) UIProgressView *progressView;

@end

@implementation ETRServerAPIHelper

+ (BOOL)didStartConnection:(NSString *)connectionID {
    if (!connectionID) {
        return NO;
    }
    
    if (!connections) {
        connections = [NSMutableArray array];
    } else if ([connections containsObject:connectionID]) {
        NSLog(@"DEBUG: Not performing %@ because the same call has already been started.", connectionID);
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
    
    
    if ([ETRServerAPIHelper didStartConnection:connectionID]) {
        return;
    }
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data,
                                               NSError *connectionError) {
                               [ETRServerAPIHelper didFinishConnection:connectionID];
                               
                               if (!handler) {
                                   NSLog(@"ERROR: No completionHandler given for API call: %@", connectionID);
                                   return;
                               }
                               
                               if (!connectionError && data) {
                                   NSError *error;
                                   NSDictionary *JSONDict = [NSJSONSerialization JSONObjectWithData:data
                                                                                            options:kNilOptions
                                                                                              error:&error];
                                   if (error) {
                                       NSLog(@"ERROR: performApiCall: %@", error);
                                       handler(nil);
                                       return;
                                   }
                                   
                                   NSString *status = (NSString *)[JSONDict objectForKey:ETRAPIStatusKey];
                                   if (!status) {
                                       handler(nil);
                                       return;
                                   }
                                   
                                   if ([status isEqualToString:successStatus]) {
                                       // The call returned a success status code.
                                       if (!objectTag) {
                                           handler([NSNumber numberWithBool:YES]);
                                       } else {
                                           id<NSObject> receivedObject = [JSONDict objectForKey:objectTag];
                                           if (!receivedObject) {
                                               handler([NSNumber numberWithBool:YES]);
                                           } else {
                                               handler(receivedObject);
                                           }
                                       }
                                       
                                       return;
                                   }
                               }
                               
                               // Something went wrong.
                               // If an Object was expected, return nil.
                               // If a boolean was expected, return NO.
                               if (!objectTag) {
                                   handler([NSNumber numberWithBool:NO]);
                               } else {
                                   handler(nil);
                               }
                           }];
}

+ (void)performAPICall:(NSString *)apiCall
        POSTBodyString:(NSString *)bodyString
         successStatus:(NSString *)successStatus
             objectTag:(NSString *)objectTag
     completionHandler:(void (^)(id<NSObject> receivedObject)) handler {
    
    // Prepare the URL to the give PHP file.
    NSString *URLString = [NSString stringWithFormat:@"%@%@", ETRAPIBaseURL, apiCall];
    NSURL *url = [NSURL URLWithString:
                  [URLString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    
    // Prepare the POST request with the given data string.
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    
    NSData * bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding
                                 allowLossyConversion:YES];
    [request setHTTPBody:bodyData];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:ETRAPITimeOutInterval];
        
//    NSString * bodyString = [NSString stringWithFormat:@"%@", bodyString];
    
    
#ifdef DEBUG
    NSLog(@"POST request: %@?%@", apiCall, bodyString);
#endif
    
    [ETRServerAPIHelper performAPIRequest:request
                                   withID:apiCall
                            successStatus:successStatus
                                objectTag:objectTag
                        completionHandler:handler];
}

+ (void)updateRoomListWithCompletionHandler:(void(^)(BOOL didReceive))completionHandler {
    NSString *connectionId = @"roomListUpdate";
//    if ([ETRServerAPIHelper didStartConnection:connectionId]) {
//        return;
//    }
    
    CLLocation *location = [ETRLocationManager location];
    if (!location) {
        NSLog(@"WARNING: Not updating Room list because Location is unknown.");
        completionHandler(NO);
        return;
    }
    
    // Get the current coordinates from the main manager.
    CLLocationCoordinate2D coordinate;
    coordinate = [location coordinate];
    
    // Build the string using coordinates, radius and unit appendage.
    NSString *bodyString;
    bodyString = [NSMutableString stringWithFormat:@"lat=%f&lng=%f&dist=%d",
                  coordinate.latitude,
                  coordinate.longitude,
                  ETRDefaultSearchRadius];
    
    [ETRServerAPIHelper performAPICall:ETRGetRoomsAPICall
                              POSTBodyString:bodyString
                         successStatus:ETRGetRoomsSuccessStatus
                             objectTag:@"rs"
                     completionHandler:^(NSObject *receivedObject) {
                         [ETRServerAPIHelper didFinishConnection:connectionId];
                         
                         // Check if an array of rooms was returned by this API call.
                         if (receivedObject && [receivedObject isKindOfClass:[NSArray class]]) {
                             
                             NSArray *jsonRooms = (NSArray *) receivedObject;
                             for (NSObject *jsonRoom in jsonRooms) {
                                 if ([jsonRoom isKindOfClass:[NSDictionary class]]) {
                                     [ETRCoreDataHelper insertRoomFromDictionary:(NSDictionary *) jsonRoom];
                                 }
                             }
                             if (completionHandler) {
                                 completionHandler([jsonRooms count]);
                                 return;
                             }
                         }
                         
                         if (completionHandler) {
                             completionHandler(NO);
                         }
                     }];
    
    return;
}

#pragma mark -
#pragma mark Images

+ (void)getImageForLoader:(ETRImageLoader *)imageLoader doLoadHiRes:(BOOL)doLoadHiRes {
    if (!imageLoader) {
        return;
    }
    
    ETRChatObject *chatObject = [imageLoader chatObject];
    if (!chatObject) return;
    if (![chatObject imageID]) return;
    NSString *fileID = [chatObject imageFileName:doLoadHiRes];
    if ([ETRServerAPIHelper didStartConnection:fileID]) {
        return;
    }
    
    // Prepare the URL to the download script.
    NSString *URLString = [NSString stringWithFormat:@"%@%@", ETRAPIBaseURL, @"download_image"];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    // Prepare the POST request.
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    
    
    NSString *bodyString = [NSString stringWithFormat:@"image_id=%@", fileID];
    NSData *bodyData = [bodyString dataUsingEncoding:NSASCIIStringEncoding];
    [request setHTTPBody:[NSMutableData dataWithData:bodyData]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:ETRAPITimeOutInterval];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               [ETRServerAPIHelper didFinishConnection:fileID];
                               
                               if (connectionError || !data) {
                                   NSLog(@"ERROR: loadImageFromUrlString: %@", connectionError);
                                   return;
                               }
                               
                               // Try to build an image from the received data.
                               UIImage *image = [[UIImage alloc] initWithData:data];
                               // Release the data and clear the connection.
                               data = nil;
                               
                               if (!image) {
                                   NSLog(@"ERROR: No image in connection data.");
                                   return;
                               }
                               
                               // Display the image and store the image file
                               // and the low-res image inside of the Object.
                               [ETRImageEditor cropImage:image
                                             applyToView:[imageLoader targetImageView]
                                                 withTag:(int) [chatObject imageID]];
                               
                               ETRChatObject *loaderObject = [imageLoader chatObject];
                               if (!doLoadHiRes && loaderObject) {
                                   [loaderObject setLowResImage:image];
                               }
                               [UIImageJPEGRepresentation(image, 1.0f) writeToFile:[loaderObject imageFilePath:doLoadHiRes]
                                                                        atomically:YES];
                           }];
}

+ (void)putImageWithHiResData:(NSData *)hiResData
                    loResData:(NSData *)loResData
            completionHandler:(void (^)(NSNumber * imageID))completionHandler {
    
    // Prepare the URL to the download script.
    NSString *URLString = [NSString stringWithFormat:@"%@%@", ETRAPIBaseURL, ETRPutImageAPICall];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    // Prepare the POST request.
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"POST"];
    //    [request setTimeoutInterval:kHTTPTimeout];
    [request setURL:URL];
    
    // Build a multi-field POST HTTP request.
    NSString *boundary = @"0xKhTmLbOuNdArY";
    NSString *boundaryReturned = [NSString stringWithFormat:@"\r\n--%@\r\n",boundary];
    // Header:
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *bodyData = [NSMutableData data];
    [bodyData appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    // The big image:
    [bodyData appendData:[@"Content-Disposition: form-data; name=\"userfile\"; filename=\"upimg.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [bodyData appendData:[@"Content-Type: image/jpg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [bodyData appendData:hiResData];
//    [bodyData appendData:[NSData dataWithData:UIImageJPEGRepresentation(image, 0.9f)]];
    [bodyData appendData:[boundaryReturned dataUsingEncoding:NSUTF8StringEncoding]];
    // The preview image:
    [bodyData appendData:[@"Content-Disposition: form-data; name=\"userfile_s\"; filename=\"upimgs.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [bodyData appendData:[@"Content-Type: image/jpg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [bodyData appendData:loResData];
//    [bodyData appendData:[NSData dataWithData:UIImageJPEGRepresentation(smallImage, 0.7f)]];
    [bodyData appendData:[boundaryReturned dataUsingEncoding:NSUTF8StringEncoding]];
    
    // Local User ID:
    [bodyData appendData:[@"Content-Disposition: form-data; name=\"user\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    NSString *userID = [[[[ETRLocalUserManager sharedManager] user] remoteID] stringValue];
    [bodyData appendData:[userID dataUsingEncoding:NSUTF8StringEncoding]];
    [bodyData appendData:[boundaryReturned dataUsingEncoding:NSUTF8StringEncoding]];
    
    // Session Room ID (optional parameter):
    ETRRoom *sessionRoom = [ETRSessionManager sessionRoom];
    if (sessionRoom) {
        [bodyData appendData:[@"Content-Disposition: form-data; name=\"session\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        NSString *roomID = [[sessionRoom remoteID] stringValue];
        [bodyData appendData:[roomID dataUsingEncoding:NSUTF8StringEncoding]];
        [bodyData appendData:[boundaryReturned dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    
    [request setHTTPBody:bodyData];
    [ETRServerAPIHelper performAPIRequest:request
                                   withID:[loResData description]
                            successStatus:ETRPutImageSuccessStatus
                                objectTag:@"i"
                        completionHandler:^(id<NSObject> receivedObject) {
                         if (receivedObject && [receivedObject isKindOfClass:[NSString class]]) {
                             NSLog(@"DEBUG: Put image got ID: %@", receivedObject);
                             NSString * remoteImageID = (NSString *)receivedObject;
                             completionHandler(@((long) [remoteImageID longLongValue]));
                         } else {
                             completionHandler(@(-19));
                         }
                     }];
    
//    [NSURLConnection sendAsynchronousRequest:request
//                                       queue:[[NSOperationQueue alloc] init]
//                           completionHandler:^(NSURLResponse *response,
//                                               NSData *data,
//                                               NSError *connectionError) {
//                               
//                               if (connectionError) {
//                                   NSLog(@"ERROR: %@", connectionError);
//                                   completionHandler(NO);
//                                   return;
//                               }
//                               
//                               NSLog(@"INFO: upload_image returns: %@",
//                                     [NSString stringWithUTF8String:[data bytes]]);
//                               completionHandler(YES);
//                           }];
}

#pragma mark -
#pragma mark InSession

- (void)joinRoom:(ETRRoom *)room
showProgressInLabel:(UILabel *)label
    progressView:(UIProgressView *)progressView
completionHandler:(void(^)(BOOL didSucceed))completionHandler {
    if (!room) {
        completionHandler(NO);
        return;
    }
    
    _progressLabel = label;
    _progressView = progressView;
    
    long roomID = [[room remoteID] longValue];
    long localUserID = [ETRLocalUserManager userID];
    
    // Prepare the block that will be called at the end.
    // This will always call the
    void (^getMessagesCompletionHandler) (id<NSObject>) = ^(id<NSObject> receivedObject) {
        if ([[NSThread currentThread] isCancelled]) {
            [NSThread exit];
            return;
        }
        
        [NSThread detachNewThreadSelector:@selector(updateProgress:)
                                 toTarget:self
                               withObject:@(0.9f)];
        
        if (!receivedObject) {
            completionHandler(NO);
            return;
        }
        
        if ([receivedObject isKindOfClass:[NSArray class]]) {
            NSArray *jsonActions = (NSArray *) receivedObject;
            for (NSObject *jsonAction in jsonActions) {
                if ([jsonAction isKindOfClass:[NSDictionary class]]) {
                    [ETRCoreDataHelper handleActionFromDictionary:(NSDictionary *)jsonAction];
                }
            }

        }
        
        if ([[NSThread currentThread] isCancelled]) {
            [NSThread exit];
        } else {
            completionHandler([[ETRSessionManager sharedManager] startSession]);
        }
    };
    
    // Prepare the block that will be called at at the end of getting the User list.
    // This block starts the message loading.
    void (^getUsersCompletionHandler) (id<NSObject>) = ^(id<NSObject> receivedObject) {
        if ([[NSThread currentThread] isCancelled]) {
            [NSThread exit];
            return;
        }
        
        if (!receivedObject) {
            completionHandler(NO);
            return;
        }
        
        if ([receivedObject isKindOfClass:[NSArray class]]) {
            NSArray *jsonUsers = (NSArray *) receivedObject;
            // TODO: Clean up "lastKnownRoom" column.
            for (NSObject *jsonUser in jsonUsers) {
                if ([jsonUser isKindOfClass:[NSDictionary class]]) {
                    ETRUser *sessionUser;
                    sessionUser = [ETRCoreDataHelper insertUserFromDictionary:(NSDictionary *)jsonUser];
                    if (sessionUser) {
                        [sessionUser setLastKnownRoom:room];
                    }
                }
            }
            
            // Update the UI to show the upcoming step.
            [NSThread detachNewThreadSelector:@selector(updateProgress:)
                                     toTarget:self
                                   withObject:@(0.7f)];
            [NSThread detachNewThreadSelector:@selector(updateProgressLabelText:)
                                     toTarget:self
                                   withObject:@"Loading messages..."];
            
            NSString *getActionsFormat = @"room_id=%ld&user_id=%ld&initial=1&blocked=%@";
            NSString *blockedIDs = @"0";
            // TODO: Add IDs of blocked Users.
            NSString *getActionsBody;
            getActionsBody = [NSString stringWithFormat:getActionsFormat, roomID, localUserID, blockedIDs];
            [ETRServerAPIHelper performAPICall:ETRGetActionsAPICall
                                      POSTBodyString:getActionsBody
                                 successStatus:ETRGetActionsSuccessStatus
                                     objectTag:ETRGetActionsObjectTag
                             completionHandler:getMessagesCompletionHandler];
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
            NSNumber *didSucceed = (NSNumber *) receivedObject;
            if ([didSucceed boolValue]) {
                // Update the UI to show the upcoming step.
                [NSThread detachNewThreadSelector:@selector(updateProgress:)
                                         toTarget:self
                                       withObject:@(0.4f)];
                [NSThread detachNewThreadSelector:@selector(updateProgressLabelText:)
                                         toTarget:self
                                       withObject:@"Loading Users..."];
                
                NSString *userListBody;
                userListBody = [NSString stringWithFormat:@"room_id=%ld", roomID];
                [ETRServerAPIHelper performAPICall:ETRGetRoomUsersAPICall
                                          POSTBodyString:userListBody
                                     successStatus:ETRRoomUsersSuccessStatus
                                         objectTag:ETRUserListObjectTag
                                 completionHandler:getUsersCompletionHandler];
                return;
            }
        }
        
        completionHandler(NO);
    };
    
    NSString *joinBody;
    joinBody = [NSString stringWithFormat:@"room_id=%ld&user_id=%ld", roomID, localUserID];
    
    [ETRCoreDataHelper clearPublicActions];
    
    [ETRServerAPIHelper performAPICall:ETRJoinRoomAPICall
                        POSTBodyString:joinBody
                         successStatus:ETRJoinRoomSuccessStatus
                             objectTag:nil
                     completionHandler:joinBlock];
}


+ (void)putAction:(ETRAction *)outgoingAction {
    if (!outgoingAction) {
        return;
    }
    
    ETRRoom *sessionRoom = [ETRSessionManager sessionRoom];
    if (!sessionRoom) {
        NSLog(@"ERROR: Cannot send an Action outside of a Session.");
        return;
    }
    long roomID = [[sessionRoom remoteID] longValue];
    
    long recipientID;
    if ([outgoingAction isPublicMessage]) {
        recipientID = ETRActionPublicUserID;
    } else if ([outgoingAction recipient]) {
        recipientID = [[[outgoingAction recipient] remoteID] longValue];
    } else {
        NSLog(@"ERROR: Could not determine Recipient ID for outgoing Action.");
        return;
    }
    
    long timestamp = [[outgoingAction sentDate] timeIntervalSince1970];
    
    NSMutableString *bodyString;
    bodyString = [NSMutableString stringWithFormat:@"room_id=%ld&sender_id=%ld&recip_id=%ld&timestamp=%ld&code=%d",
                  roomID,
                  [ETRLocalUserManager userID],
                  recipientID,
                  timestamp,
                  [[outgoingAction code] shortValue]];
    
    NSString *successStatus;
    if ([outgoingAction isValidMessage]) {
        [bodyString appendFormat:@"&message=%@", [outgoingAction messageContent]];
        successStatus = ETRPutMessageSuccessStatus;
    } else {
        successStatus = ETRPutActionSuccessStatus;
    }
    
    [ETRServerAPIHelper performAPICall:ETRPutActionAPICall
                              POSTBodyString:bodyString
                         successStatus:successStatus
                             objectTag:nil
                     completionHandler:^(id<NSObject> receivedObject) {
                         
                         if ([receivedObject isKindOfClass:[NSNumber class]]) {
                             NSNumber *didSucceed = (NSNumber *)receivedObject;
                             if ([didSucceed boolValue]) {
                                 NSLog(@"DEBUG: Did successfully send Action: %@", [outgoingAction messageContent]);
                                 [ETRCoreDataHelper removeActionFromQueue:outgoingAction];
                                 return;
                             }
                         }
                         
                         [ETRCoreDataHelper addActionToQueue:outgoingAction];
                     }];
}

#pragma mark -
#pragma mark User

/*
 Registers a new User at the database or retrieves the data
 that matches the combination of the given name and device ID;
 stores the new User object through the Local User Manager when finished
 */
+ (void)loginUserWithName:(NSString *)name completionHandler:(void(^)(ETRUser *))onSuccessBlock {
    NSString* uuid;
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
        // IOS 6 new Unique Identifier implementation, IFA
        uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    } else {
        uuid = [NSString stringWithFormat:@"%@-%ld", [[UIDevice currentDevice] systemVersion], random()];
    }
    
    NSString *status = NSLocalizedString(@"send_me_realhey", @"Default status message");
    NSString *body = [NSString stringWithFormat:@"name=%@&device_id=%@&status=%@", name, uuid, status];
    
    [ETRServerAPIHelper performAPICall:@"get_local_user"
                              POSTBodyString:body
                         successStatus:@"SU_OK"
                             objectTag:@"user"
                     completionHandler:^(id<NSObject> receivedObject) {
                         if (receivedObject && [receivedObject isKindOfClass:[NSDictionary class]]) {
                             NSDictionary *jsonDictionary;
                             jsonDictionary = (NSDictionary *) receivedObject;
                             ETRUser *localUser;
                             localUser = [ETRCoreDataHelper insertUserFromDictionary:jsonDictionary];
                             
                             if (localUser) {
                                 [[ETRLocalUserManager sharedManager] setUser:localUser];
                                 [[ETRLocalUserManager sharedManager] storeUserDefaults];
                                 onSuccessBlock(localUser);
                                 return;
                             }
                         }
                         
                         onSuccessBlock(nil);
                         
                     }];
}

+ (void)sendLocalUserUpdate {
    
}

+ (void)getUserWithID:(long)remoteID {
    if (remoteID < 10) {
        return;
    }
    
    NSString *connectionID = [NSString stringWithFormat:@"getUser:%ld", remoteID];
//    if ([ETRServerAPIHelper didStartConnection:connectionID]) {
//        return;
//    }
    
    NSString *body = [NSString stringWithFormat:@"user_id=%ld", remoteID];
    [ETRServerAPIHelper performAPICall:ETRGetUserAPICall
                              POSTBodyString:body
                         successStatus:ETRGetUserSuccessStatus
                             objectTag:ETRUserObjectTag
                     completionHandler:^(id<NSObject> receivedObject) {
                         if (receivedObject && [receivedObject isKindOfClass:[NSDictionary class]]) {
                             NSDictionary *jsonDictionary;
                             jsonDictionary = (NSDictionary *) receivedObject;
                             [ETRCoreDataHelper insertUserFromDictionary:jsonDictionary];
                         }
                     }];
}

#pragma mark -
#pragma mark UI Updates

- (void)updateProgressLabelText:(NSString *)text {
    if (!_progressLabel) {
        return;
    }
    
    [_progressLabel setText:text];
}

- (void)updateProgress:(NSNumber *)progress {
    if (!_progressView || !progress) {
        return;
    }
    [_progressView setProgress:[progress floatValue]];
}

@end
