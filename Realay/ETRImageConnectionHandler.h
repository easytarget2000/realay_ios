//
//  ETRImageConnectionHandler.h
//  Realay
//
//  Created by Michel on 26/02/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ETRImageLoader.h"

@interface ETRImageConnectionHandler : NSObject <NSURLConnectionDataDelegate>

- (id)initWithImageLoader:(ETRImageLoader *) imageLoader doLoadHiRes:(BOOL)doLoadHiRes;

+ (void)performRequest:(NSURLRequest *) request forLoader:(ETRImageLoader *)imageLoader doLoadHiRes:(BOOL) doLoadHiRes;

@end
