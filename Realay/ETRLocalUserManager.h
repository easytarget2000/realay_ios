//
//  ETRLocalUser.h
//  Realay
//
//  Created by Michel S on 17.02.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRUser.h"

@interface ETRLocalUserManager : NSObject

@property (strong, nonatomic) NSString *deviceId;

@property (strong, nonatomic) ETRUser *user;

/*
 Same as user.iden
 */
- (long)userID;

/*
 Stores the User object in the preferences
 */
- (void)storeUserDefaults;

/*
 Stores the User on the remote Server
 */
- (BOOL)putUserRemote;

/*
 The shared singleton instance:
 */
+ (ETRLocalUserManager *)sharedManager;

@end
