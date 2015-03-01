//
//  ETRDbHandler.m
//  Realay
//
//  Created by Michel S on 18.02.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRServerAPIHelper.h"

#import "ETRAppDelegate.h"
#import "ETRLocalUserManager.h"
#import "ETRSession.h"
#import "ETRImageConnectionHandler.h"

#define kServerURL              @"http://rldb.easy-target.org/"

#define kTimeoutInterval        20

#define kApiStatusKey           @"st"
#define kApiCallRoomList        @"select_rooms"
#define kApiCallGetImage        @"download_image"

#define kDefaultSearchRadius    20

@implementation ETRServerAPIHelper

+ (void)performAPICall:(NSString *) apiCall
              POSTbody:(NSString *) bodyString
         successStatus:(NSString *) successStatus
             objectTag:(NSString *) objectTag
     completionHandler:(void (^)(id<NSObject> receivedObject)) handler {
    
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

+ (void)loadImageFromUrlString:(NSString *)URLString intoImageView:(UIImageView *)imageView{
    NSURL *url = [NSURL URLWithString: URLString];
    //    UIImage __block *loadedImage;
    NSError __block *httpError;
    
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        if (!connectionError) {
            if (data) [imageView setImage:[UIImage imageWithData:data]];
        } else {
            httpError = connectionError;
            NSLog(@"ERROR: loadImageFromUrlString: %@", connectionError);
        }
        
    }];
    
    // Go into a RunLoop while the JSON array is not initialised.
    //NSDate *timeout = [[NSDate date] dateByAddingTimeInterval:HTTP_TIMEOUT];
    //NSRunLoop *runLoop = [NSRunLoop ];
    //while (!httpError && !loadedImage && [runLoop runMode:NSDefaultRunLoopMode beforeDate:timeout]);
    
    //    if (!loadedImage) {
    //        NSLog(@"ERROR: Downloaded image returned null.");
    //        return nil;
    //    }
}

+ (void)updateRoomList {
    // Get the current coordinates from the main manager.
    CLLocationCoordinate2D coordinate;
    coordinate = [[[[ETRSession sharedManager] locationManager] location] coordinate];
    
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
                             ETRAppDelegate *app = (ETRAppDelegate *)[[UIApplication sharedApplication] delegate];
                             NSManagedObjectContext * context = [app managedObjectContext];
                             if (!context) return;
                             
                             NSArray *jsonRooms = (NSArray *) receivedObject;
                             for (NSObject *jsonRoom in jsonRooms) {
                                 if ([jsonRoom isKindOfClass:[NSDictionary class]]) {
                                     ETRRoom *room = [ETRRoom roomFromJSONDictionary:(NSDictionary *)jsonRoom];
                                     [context insertObject:room];
                                 }
                             }
                             
                             NSLog(@"Received %ld rooms.", [jsonRooms count]);
                         }
                     }];
    
    return;
}

+ (void)getImageLoader:(ETRImageLoader *)imageLoader doLoadHiRes:(BOOL)doLoadHiRes {
    if (!imageLoader) return;
    
    // Prepare the URL to the download script.
    NSString *URLString = [NSString stringWithFormat:@"%@%@", kServerURL, @"download_image"];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    // Prepare the POST request.
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    
    ETRChatObject *chatObject = [imageLoader chatObject];
    if (!chatObject) return;
    if (![chatObject imageID]) return;
    NSString *bodyString = [NSString stringWithFormat:@"image_id=%@", [chatObject imageIDWithHiResFlag:doLoadHiRes]];
    NSData *bodyData = [bodyString dataUsingEncoding:NSASCIIStringEncoding];
    [request setHTTPBody:[NSMutableData dataWithData:bodyData]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:kTimeoutInterval];
    
    [ETRImageConnectionHandler performRequest:request forLoader:imageLoader doLoadHiRes:doLoadHiRes];
}

/*
 Registers a new User at the database or retrieves the data
 that matches the combination of the given name and device ID;
 stores the new User object through the Local User Manager when finished
 */
+ (void)loginUserWithName:(NSString *)name onSuccessBlock:(void(^)(User *localUser))onSuccessBlock {
    NSString* uuid;
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
        // IOS 6 new Unique Identifier implementation, IFA
        uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    } else {
        uuid = [NSString stringWithFormat:@"%@-%ld", [[UIDevice currentDevice] systemVersion], random()];
    }
    
    NSString *body = [NSString stringWithFormat:@"name=%@&device_id=%@", name, uuid];
    
    [ETRServerAPIHelper performAPICall:@"get_id_reg"
                              POSTbody:body
                         successStatus:@"IU_OK"
                             objectTag:@"u"
                     completionHandler:^(id<NSObject> receivedObject) {
                         if (!receivedObject) return;
                         
                         if ([receivedObject isKindOfClass:[NSArray class]]) {
                             NSLog(@"%@", receivedObject);
                             onSuccessBlock(nil);
                         }
                     }];
}

@end
