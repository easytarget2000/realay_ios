//
//  ETRDbHandler.h
//  Realay
//
//  Created by Michel S on 18.02.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ETRHTTPHandler : NSObject

// Finds a specific image on the server by its ID and asynchronously stores the data.
+ (UIImage *)downloadImageWithID:(NSString *)imageID;

// Sends the given body string as an HTTP POST request to the given PHP script
// and return the received data as a JSON dictionary.
// The server and path to the PHP file are known.
+ (NSDictionary *)JSONDictionaryFromPHPScript:(NSString *)PHPFileName
                                   bodyString:(NSString *)bodyString;

// Queries the list of rooms that are inside a given distance radius.
+ (NSArray *)queryRoomListInRadius:(CGFloat)radius;


@end
