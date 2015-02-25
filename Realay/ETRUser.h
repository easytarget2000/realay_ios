//
//  RLUser.h
//  Realay
//
//  Created by Michel S on 11.12.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class ETRUser;

@protocol ETRUserDelegate <NSObject>

- (void)userDidFinishUpdating:(ETRUser *)user;

@end

@interface ETRUser : NSObject

@property (weak, nonatomic)     id<ETRUserDelegate> delegate;

@property (nonatomic)           NSInteger   userID;
@property (strong, nonatomic)   NSString    *userKey;
@property (strong, nonatomic)   NSString    *name;
@property (strong, nonatomic)   NSString    *status;
@property (strong, nonatomic)   NSString    *imageID;
@property (strong, nonatomic)   UIImage     *image;
@property (strong, nonatomic)   UIImage     *smallImage;
@property (strong, nonatomic)   NSString    *emailAddress;
@property (strong, nonatomic)   NSString    *phoneNumber;
@property (strong, nonatomic)   CLLocation  *location;
@property (strong, nonatomic)   NSString    *deviceId;

//+ (ETRUser *)dummyPublicChatUser;
+ (ETRUser *)userWithIDKey:(NSString *)key;
+ (ETRUser *)userFromJSONDictionary:(NSDictionary *)JSONDict;
//+ (ETRUser *)userWithID:(NSInteger)databaseID name:(NSString *)name;
+ (ETRUser *)userPartnerInChat:(NSInteger)chatID;

-(void)refreshImage;

@end
