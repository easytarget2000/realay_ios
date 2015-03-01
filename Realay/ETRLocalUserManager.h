//
//  ETRLocalUser.h
//  Realay
//
//  Created by Michel S on 17.02.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "User.h"

@interface ETRLocalUserManager : NSObject

@property (strong, nonatomic) NSString *deviceId;

@property (strong, nonatomic) User *user;

/*
 Same as user.iden
 */
- (long)userID;

/*
 Stores the User object in the preferences and in the remote database
 */
- (BOOL)storeData;

/*
 The shared singleton instance:
 */
+ (ETRLocalUserManager *)sharedManager;

@end
