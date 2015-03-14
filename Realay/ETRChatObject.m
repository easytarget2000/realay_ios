//
//  ETRChatObject.m
//  Realay
//
//  Created by Michel on 26/02/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRChatObject.h"

@implementation ETRChatObject

@dynamic remoteID;
@dynamic imageID;
@synthesize lowResImage;


- (NSString *)imageIDWithHiResFlag:(BOOL)doLoadHiRes {
    return [NSString stringWithFormat:@"%ld%s", [[self imageID] longValue], doLoadHiRes ? "" : "s"];
}


@end
