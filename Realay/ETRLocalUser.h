//
//  ETRLocalUser.h
//  Realay
//
//  Created by Michel S on 17.02.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRUser.h"

@interface ETRLocalUser : ETRUser

@property (strong, nonatomic) NSString *deviceId;

- (void)restoreFromUserDefaults;
- (BOOL)insertNewLocalUserWithName:(NSString *)name;
- (BOOL)wasAbleToUpdateUser;
- (void)updateImage:(UIImage *)image;

// The shared singleton instance:
+ (ETRLocalUser *)sharedLocalUser;

@end
