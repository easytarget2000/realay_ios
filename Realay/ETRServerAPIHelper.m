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
#import "ETRSession.h"

#define kServerURL              @"http://rldb.easy-target.org/"

#define kTimeoutInterval        20

#define kApiStatusKey           @"st"
#define kApiCallRoomList        @"select_rooms"
#define kApiCallGetImage        @"download_image"

#define kDefaultSearchRadius    20

static NSMutableArray *connections;

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

+ (void)performAPICall:(NSString *) apiCall
              POSTbody:(NSString *) bodyString
         successStatus:(NSString *) successStatus
             objectTag:(NSString *) objectTag
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
                                       handler(nil);
                                       return;
                                   }
                                   
                                   NSString *status = (NSString *)[JSONDict objectForKey:kApiStatusKey];
                                   if (!status) {
                                       handler(nil);
                                       return;
                                   }
                                   
                                   if ([status isEqualToString:successStatus]) {
                                       id<NSObject> receivedObject = [JSONDict objectForKey:objectTag];
                                       handler(receivedObject);
                                       return;
                                   }
                               }
                               
                               handler(nil);
                           }];
}

+ (void)updateRoomList {
    CLLocation *location = [ETRLocationHelper location];
    if (!location) {
        NSLog(@"WARNING: Not updating Room list because Location is unknown.");
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
                             ETRCoreDataHelper *dataBridge = [ETRCoreDataHelper helper];
                             
                             NSArray *jsonRooms = (NSArray *) receivedObject;
                             for (NSObject *jsonRoom in jsonRooms) {
                                 if ([jsonRoom isKindOfClass:[NSDictionary class]]) {
                                     [dataBridge insertRoomFromDictionary:(NSDictionary *) jsonRoom];
                                 }
                             }
                         }
                     }];
    
    return;
}

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

/*
 Registers a new User at the database or retrieves the data
 that matches the combination of the given name and device ID;
 stores the new User object through the Local User Manager when finished
 */
+ (void)loginUserWithName:(NSString *)name onSuccessBlock:(void(^)(ETRUser *))onSuccessBlock {
    NSString* uuid;
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
        // IOS 6 new Unique Identifier implementation, IFA
        uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    } else {
        uuid = [NSString stringWithFormat:@"%@-%ld", [[UIDevice currentDevice] systemVersion], random()];
    }
    
    // TODO: Localize.
    NSString *status = @"Send me a RealHey!";
    NSString *body = [NSString stringWithFormat:@"name=%@&device_id=%@&status=%@", name, uuid, status];
    
    [ETRServerAPIHelper performAPICall:@"get_local_user"
                              POSTbody:body
                         successStatus:@"SU_OK"
                             objectTag:@"user"
                     completionHandler:^(id<NSObject> receivedObject) {
                         if (receivedObject && [receivedObject isKindOfClass:[NSDictionary class]]) {
                             ETRJSONDictionary *jsonDictionary;
                             jsonDictionary = (ETRJSONDictionary *) receivedObject;
                             ETRUser *localUser;
                             localUser = [[ETRCoreDataHelper helper] insertUserFromDictionary:jsonDictionary];
                             
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

@end
