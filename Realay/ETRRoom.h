//
//  Room.h
//  Realay
//
//  Created by Michel on 13.09.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

#import "ETRChatObject.h"

@protocol ETRRoomDelegate <NSObject>

- (void)roomDidUpdateUserList;

@end

@interface ETRRoom : ETRChatObject

@property (weak, nonatomic)     id<ETRRoomDelegate> delegate;

@property (strong, nonatomic)   NSString    *title;
@property (strong, nonatomic)   NSString    *info;
@property (strong, nonatomic)   NSString    *password;
@property (nonatomic)           NSInteger   userCount;
@property (strong, nonatomic)   NSDate      *startDate;
@property (strong, nonatomic)   NSDate      *endDate;
@property (strong, nonatomic)   NSString    *address;
@property (nonatomic)           CLLocation  *location;
@property (nonatomic)           NSInteger   radius;
@property (nonatomic)           CGFloat     queryDistance;

+ (ETRRoom *)roomFromJSONDictionary:(NSDictionary *)JSONDict;

- (NSString *)timeSpan;
- (NSString *)size;
- (NSString *)coordinateString;
- (NSString *)amountOfUsersString;
- (NSString *)infoString;

@end
