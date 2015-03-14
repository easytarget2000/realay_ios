//
//  Room.h
//  Realay
//
//  Created by Michel on 01/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "ETRChatObject.h"

@class ETRUser;

@interface ETRRoom : ETRChatObject

@property (nonatomic, retain) NSString * address;

@property (nonatomic, retain) NSString * createdBy;

@property (nonatomic, retain) NSDate * endDate;

@property (nonatomic, retain) NSNumber * latitude;

@property (nonatomic, retain) NSNumber * longitude;

@property (nonatomic, retain, readonly) CLLocation * location;

@property (nonatomic, retain) NSString * password;

@property (nonatomic, retain) NSNumber * queryDistance;

@property (nonatomic, retain) NSNumber * radius;

@property (nonatomic, retain) NSDate * startTime;

@property (nonatomic, retain) NSString * summary;

@property (nonatomic, retain) NSString * title;

@property (nonatomic, retain) NSNumber * queryUserCount;

@property (nonatomic, retain) NSSet *users;

@property (nonatomic, retain) NSManagedObject *actions;

- (NSString *)description;

- (NSString *)formattedCoordinates;

- (NSString *)userCount;

@end

@interface ETRRoom (CoreDataGeneratedAccessors)

- (void)addUsersObject:(ETRUser *)value;
- (void)removeUsersObject:(ETRUser *)value;
- (void)addUsers:(NSSet *)values;
- (void)removeUsers:(NSSet *)values;

@end
