//
//  ETRIconDownloader.h
//  Realay
//
//  Created by Michel S on 11.03.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRRoom.h"
#import "ETRUser.h"

@interface ETRIconDownloader : NSObject <NSURLConnectionDataDelegate>

@property (strong, nonatomic) void (^completionHandler)(void);

- initWithRoom:(ETRRoom *)room;

- (void)startDownload;
- (void)cancelDownload;

@end
