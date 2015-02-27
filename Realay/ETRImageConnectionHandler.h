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

+ (void)loadForLoader:(ETRImageLoader *)imageLoader doLoadHiRes:(BOOL)doLoadHiRes;

@end
