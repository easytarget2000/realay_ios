//
//  ETRDbHandler.m
//  Realay
//
//  Created by Michel S on 18.02.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRServerAPIHelper.h"

#import "ETRImageConnectionHandler.h"
#import "ETRImageEditor.h"
#import "ETRImageLoader.h"
#import "ETRCoreDataHelper.h"
#import "ETRLocalUserManager.h"
#import "ETRLocationManager.h"
#import "ETRRoom.h"
#import "ETRSession.h"
#import "ETRUser.h"

#define kServerURL                  @"http://rldb.easy-target.org/"

#define kTimeoutInterval            20

#define kApiStatusKey               @"st"
#define kApiCallRoomList            @"select_rooms"
#define kApiCallGetImage            @"download_image"

#define kDefaultSearchRadius        20

static NSString *const getRoomsAPICall = @"get_rooms";

static NSString *const getRoomsSuccessStatus = @"RS_OK";

static NSString *const getActionsAPICall = @"get_actions";

static NSString *const getActionsSuccessStatus = @"AS_OK";

static NSString *const getActionsObjectTag = @"as";

static NSMutableArray *connections;

@interface ETRServerAPIHelper ()

@property (strong, nonatomic) UILabel *progressLabel;

@property (strong, nonatomic) UIProgressView *progressView;

@end

@implementation ETRServerAPIHelper

+ (BOOL)didStartConnection:(NSString *)connectionID {
    if (!connections) {
        connections = [NSMutableArray array];
    } else if ([connections containsObject:connectionID]) {
        NSLog(@"DEBUG: Not performing %@ because the same call has already been started.", connectionID);
        return true;
    }
    
    [connections addObject:connectionID];
    return false;
}

+ (void)didFinishConnection:(NSString *)connectionID {
    if (!connections) {
        connections = [NSMutableArray array];
        return;
    } else if ([connections containsObject:connectionID]){
        [connections removeObject:connectionID];
    }
}

+ (void)performAPICall:(NSString *)apiCall
              POSTbody:(NSString *)bodyString
         successStatus:(NSString *)successStatus
             objectTag:(NSString *)objectTag
     completionHandler:(void (^)(id<NSObject> receivedObject)) handler {
    
    if ([ETRServerAPIHelper didStartConnection:apiCall]) {
        return;
    }
    
    // Prepare the URL to the give PHP file.
    NSString *URLString = [NSString stringWithFormat:@"%@%@", kServerURL, apiCall];
    NSURL *url = [NSURL URLWithString:
                  [URLString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    
    // Prepare the POST request with the given data string.
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    bodyString = [NSString stringWithFormat:@"%@", bodyString];
    [request setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding
                                  allowLossyConversion:YES]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:kTimeoutInterval];
    
#ifdef DEBUG
    NSLog(@"POST request: %@?%@", url, bodyString);
#endif
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data,
                                               NSError *connectionError) {
                               [ETRServerAPIHelper didFinishConnection:apiCall];
                               
                               if (!handler) {
                                   NSLog(@"ERROR: No completionHandler given for API call: %@", apiCall);
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
                                   
                                   NSString *status = (NSString *)[JSONDict objectForKey:kApiStatusKey];
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

+ (void)updateRoomListWithCompletionHandler:(void(^)(BOOL didReceive))completionHandler {
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
                  kDefaultSearchRadius];
    
    [ETRServerAPIHelper performAPICall:kApiCallRoomList
                              POSTbody:bodyString
                         successStatus:@"RS_OK"
                             objectTag:@"rs"
                     completionHandler:^(NSObject *receivedObject) {
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
    NSString *fileID = [chatObject imageIDWithHiResFlag:doLoadHiRes];
    if ([ETRServerAPIHelper didStartConnection:fileID]) {
        return;
    }
    
    // Prepare the URL to the download script.
    NSString *URLString = [NSString stringWithFormat:@"%@%@", kServerURL, @"download_image"];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    // Prepare the POST request.
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    
    
    NSString *bodyString = [NSString stringWithFormat:@"image_id=%@", fileID];
    NSData *bodyData = [bodyString dataUsingEncoding:NSASCIIStringEncoding];
    [request setHTTPBody:[NSMutableData dataWithData:bodyData]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:kTimeoutInterval];
    
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
                               if (!doLoadHiRes && loaderObject) [loaderObject setLowResImage:image];
                               [UIImageJPEGRepresentation(image, 1.0f) writeToFile:[imageLoader imagefilePath:doLoadHiRes]
                                                                        atomically:YES];
                           }];
}

+ (void)sendImage:(UIImage *)image completionHandler:(void (^)(BOOL))completionHandler {
    
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
    long localUserID = [[ETRLocalUserManager sharedManager] userID];
    
    // Prepare the block that will be called at the end.
    // This will always call the
    void (^getMessagesCompletionHandler) (id<NSObject>) = ^(id<NSObject> receivedObject) {
        if ([[NSThread currentThread] isCancelled]) {
            [NSThread exit];
            return;
        }
        
//        [progressView setProgress:0.9f];
        if (!receivedObject) {
            completionHandler(NO);
            return;
        }
        
        
        if ([receivedObject isKindOfClass:[NSArray class]]) {
            NSArray *jsonActions = (NSArray *) receivedObject;
            for (NSObject *jsonAction in jsonActions) {
                if ([jsonAction isKindOfClass:[NSDictionary class]]) {
                    [ETRCoreDataHelper handleMessageInDictionary:(NSDictionary *)jsonAction];
                }
            }

        }
        
        if ([[NSThread currentThread] isCancelled]) {
            [NSThread exit];
        } else {
            completionHandler([[ETRSession sharedManager] startSession]);
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
                                   withObject:@(0.8f)];
            [NSThread detachNewThreadSelector:@selector(updateProgressLabelText:)
                                     toTarget:self
                                   withObject:@"Loading messages..."];
            
            NSString *getActionsFormat = @"room_id=%ld&user_id=%ld&initial=1&blocked=%@";
            NSString *blockedIDs = @"0";
            // TODO: Add IDs of blocked Users.
            NSString *getActionsBody;
            getActionsBody = [NSString stringWithFormat:getActionsFormat, roomID, localUserID, blockedIDs];
            [ETRServerAPIHelper performAPICall:getActionsAPICall
                                      POSTbody:getActionsBody
                                 successStatus:getActionsSuccessStatus
                                     objectTag:getActionsObjectTag
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
                                       withObject:@(0.8f)];
                [NSThread detachNewThreadSelector:@selector(updateProgressLabelText:)
                                         toTarget:self
                                       withObject:@"Loading Users..."];
                
                NSString *userListBody;
                userListBody = [NSString stringWithFormat:@"room_id=%ld", roomID];
                [ETRServerAPIHelper performAPICall:@"get_room_users"
                                          POSTbody:userListBody
                                     successStatus:@"UIR_OK"
                                         objectTag:@"us"
                                 completionHandler:getUsersCompletionHandler];
                return;
            }
        }
        
        completionHandler(NO);
    };
    
    NSString *joinBody;
    joinBody = [NSString stringWithFormat:@"room_id=%ld&user_id=%ld", roomID, localUserID];
    
    [ETRServerAPIHelper performAPICall:@"do_join_room"
                              POSTbody:joinBody
                         successStatus:@"INS_U_OK"
                             objectTag:nil
                     completionHandler:joinBlock];
}

+ (void)getUserListInRoom:(ETRRoom *)room {
    
}

+ (void)sendAction:(ETRAction *)action {
    
}

#pragma mark -
#pragma mark Local User

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
                              POSTbody:body
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
