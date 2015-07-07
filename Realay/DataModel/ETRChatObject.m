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


- (NSString *)imageFileName:(BOOL)doLoadHiRes {
    long imageID = [[self imageID] longValue];
    char * prefix = imageID > 0 ? "" : "t";
    char * suffix = doLoadHiRes ? "" : "s";
    
    return [NSString stringWithFormat:@"%s%ld%s", prefix, imageID, suffix];
}

- (NSString *)imageFilePath:(BOOL)isHiRes {
    // Save image.
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * fileName;
    fileName = [NSString stringWithFormat:@"%@.jpg", [self imageFileName:isHiRes]];
    return [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];
}

- (void)deleteImageFiles {
    // TODO: Implement file deletion.
}

@end
