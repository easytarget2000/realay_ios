//
//  ETRDbHandler.m
//  Realay
//
//  Created by Michel S on 18.02.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRHTTPHandler.h"

#import "ETRChat.h"
#import "ETRLocalUser.h"
#import "ETRSession.h"
#import "ETRRoom.h"

#import "SharedMacros.h"
#define kPHPSelectRooms     @"select_rooms.php"

@implementation ETRHTTPHandler

// Finds a specific image on the server by its ID and asynchronously stores the data.
+ (UIImage *)downloadImageWithID:(NSString *)imageID; {
    
    // Prepare the URL to the download script.
    NSString *URLString = [NSString stringWithFormat:@"%@%@",
                           kURLPHPScripts, kPHPDownloadImage];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    // Build the POST request.
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSString *bodyString = [NSString stringWithFormat:@"image_id=%@", imageID];
    [request setHTTPBody:[bodyString dataUsingEncoding:NSASCIIStringEncoding]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:kHTTPTimeout];
    [request setURL:URL];
    
#ifdef DEBUG
    NSLog(@"INFO: User image request started: %@", imageID);
#endif
    NSURLResponse *response;
    NSError *error;
    NSData *connectionData = [NSURLConnection sendSynchronousRequest:request
                                                   returningResponse:&response
                                                               error:&error];
    
    if (connectionData) {
        return [[UIImage alloc] initWithData:connectionData];
    } else {
        return [UIImage imageNamed:@"empty.jpg"];
    }
    
//
//    [NSURLConnection sendAsynchronousRequest:request
//                                       queue:[[NSOperationQueue alloc] init]
//                           completionHandler:^(NSURLResponse *response,
//                                               NSData *data,
//                                               NSError *connectionError) {
//                               
//                               if ([data length] > 0 && !connectionError) {
//                                   blockImage = [blockImage initWithData:data];
//                               } else if ([data length] == 0 && !connectionError) {
//                                   NSLog(@"ERROR: Image download resulted in no data.");
//                                   blockImage = [UIImage imageNamed:@"empty.jpg"];
//                               } else {
//                                   NSLog(@"ERROR: %@", connectionError);
//                                   blockImage = [UIImage imageNamed:@"empty.jpg"];
//                               }
//                           }];
    
}

+ (NSDictionary *)JSONDictionaryFromPHPScript:(NSString *)PHPFileName
                                   bodyString:(NSString *)bodyString {
    
    // Prepare the URL to the give PHP file.
    NSString *URLString = [NSString stringWithFormat:@"%@%@", kURLPHPScripts, PHPFileName];
    NSURL *url = [NSURL URLWithString:
                  [URLString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    
    // Prepare the POST request with the given data string.
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    bodyString = [NSString stringWithFormat:@"%@", bodyString];
    [request setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding
                                  allowLossyConversion:YES]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:kHTTPTimeout];
    
#ifdef DEBUG
    NSLog(@"INFO: Request: %@ with %@", url, bodyString);
#endif
    
    NSDictionary __block *JSONDict;
    NSError __block *error;
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data,
                                               NSError *connectionError) {
                               
                               if (!connectionError && data) {
                                   JSONDict = [NSJSONSerialization JSONObjectWithData:data
                                                                              options:kNilOptions
                                                                                error:&error];
                               } else {
                                   error = connectionError;
                               }
                               
                           }];
    
    while (!error && !JSONDict);
    if (error) NSLog(@"ERROR: JSONDictionaryFromURLString: %@", error);
    
    return JSONDict;
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

+ (NSArray *)queryRoomListInRadius:(CGFloat)radius {
    // Get the current coordinates from the main manager.
    CLLocationCoordinate2D coordinate;
    coordinate = [[[[ETRSession sharedSession] locationManager] location] coordinate];
    
    // Build the string using coordinates, radius and unit appendage.
    NSString *bodyString;
    bodyString = [NSMutableString stringWithFormat:@"lat=%f&lng=%f&dist=%.2f",
                            coordinate.latitude,
                            coordinate.longitude,
                            radius];
    
    // Get the JSON data and parse it.
    NSDictionary *jsonDict = [self JSONDictionaryFromPHPScript:kPHPSelectRooms
                                                    bodyString:bodyString];
    NSString *statusCode = [jsonDict objectForKey:@"st"];
    NSArray *roomsJsonArray = [jsonDict objectForKey:@"rs"];
    
#ifdef DEBUG
    NSLog(@"INFO: queryRoomList status code: %@", statusCode);
#endif
    NSMutableArray *roomsArray = [[NSMutableArray alloc] init];
    
    if (![statusCode isEqual:@"RS_OK"]) {
        NSLog(@"ERROR: %@", statusCode);
        return nil;
    } else {
        
        // Add all objects in the JSON Rooms array to the return array.
        for (NSDictionary *roomDict in roomsJsonArray) {
            [roomsArray addObject:[ETRRoom roomFromJSONDictionary:roomDict]];
        }
        
    }
    
    return roomsArray;
}

@end
