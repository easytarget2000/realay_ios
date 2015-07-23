//
//  Room.h
//  Realay
//
//  Created by Michel on 01/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRChatObject.h"

@class CLLocation;
@class ETRAction;
@class ETRUser;

@interface ETRRoom : ETRChatObject

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSString * createdBy;
@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSNumber * imageID;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSNumber * distance;
@property (nonatomic, retain) NSNumber * queryUserCount;
@property (nonatomic, retain) NSNumber * radius;
@property (nonatomic, retain) NSNumber * remoteID;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *actions;
@property (nonatomic, retain) NSSet *users;
@property (nonatomic, retain) NSSet *conversations;

- (NSString *)description;

- (CLLocation *)location;

@end

@interface ETRRoom (CoreDataGeneratedAccessors)

- (void)addActionsObject:(ETRAction *)value;
- (void)removeActionsObject:(ETRAction *)value;
- (void)addActions:(NSSet *)values;
- (void)removeActions:(NSSet *)values;

- (void)addUsersObject:(ETRUser *)value;
- (void)removeUsersObject:(ETRUser *)value;
- (void)addUsers:(NSSet *)values;
- (void)removeUsers:(NSSet *)values;

@end
