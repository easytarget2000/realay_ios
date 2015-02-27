//
//  ETRChatObject.h
//  Realay
//
//  Created by Michel on 26/02/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ETRChatObject : NSObject

@property (nonatomic) long iden;
@property (nonatomic) long imageID;
@property (strong, nonatomic) UIImage *lowResImage;

+ (NSString *)readableStringForDate:(NSDate *)date;

/*
 Takes a value in metres and returns a human readable text,
 depending on the value and the system locale:
 100 returns "100 m" or "109 yd"
 15000 returns "15 km" or "8 mi"
 */
+ (NSString *)lengthFromMetres:(NSInteger)metres;

- (NSString *)imageIDWithHiResFlag:(BOOL)doLoadHiRes;

@end
