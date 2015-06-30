//
//  ETRLocalUser.m
//  Realay
//
//  Created by Michel S on 17.02.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRLocalUserManager.h"

#import "ETRCoreDataHelper.h"
#import "ETRDefaultsHelper.h"
#import "ETRImageEditor.h"
#import "ETRImageView.h"
#import "ETRServerAPIHelper.h"
#import "ETRUser.h"


static ETRLocalUserManager * sharedInstance = nil;

@implementation ETRLocalUserManager

@synthesize user = _user;

#pragma mark -
#pragma mark Factory methods

+ (void)initialize {
    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        sharedInstance = [[ETRLocalUserManager alloc] init];
    }
}

+ (ETRLocalUserManager *)sharedManager {
    return sharedInstance;
}

- (ETRUser *)user {
    if (!_user) {
        _user = [ETRCoreDataHelper userWithRemoteID:[ETRDefaultsHelper localUserID]
                                doLoadIfUnavailable:NO];
    }
    
    return _user;
}

- (void)setUser:(ETRUser *)user {
    if (!user) {
        return;
    } else {
        _user = user;
        [self storeUserDefaults];
    }
}

+ (long)userID {
    if (![[ETRLocalUserManager sharedManager] user]) {
        return -34;
    }
    
    return [[[[ETRLocalUserManager sharedManager] user] remoteID] longValue];
}

- (void)storeUserDefaults {
    if (!_user) {
        return;
    }
    [ETRDefaultsHelper storeLocalUserID:[_user remoteID]];
}

- (BOOL)isLocalUser:(ETRUser *)user {
    if (!user || ![user remoteID] || !_user) {
        return NO;
    } else {
        return [[user remoteID] isEqualToNumber:[_user remoteID]];
    }
}

- (void)setImage:(UIImage *)newUserImage withImageView:(ETRImageView *)imageView {
    if (!newUserImage || ![self user]) {
        return;
    }
    
    // Temporary image IDs are negative, random values.
    long randomID = drand48() * LONG_MIN;
    if (randomID > 0L) {
        randomID = -randomID;
    }
    NSNumber * newImageID = @(randomID);
    
    if (imageView) {
        [ETRImageEditor cropImage:newUserImage imageName:[newImageID stringValue] applyToView:imageView];
    }
    
#ifdef DEBUG
    NSLog(@"New local User image ID: %@", [newImageID stringValue]);
#endif
    
    [_user setImageID:newImageID];
    
    NSData * loResData = [ETRImageEditor cropLoResImage:newUserImage
                                            writeToFile:[_user imageFilePath:NO]];
    
    NSData * hiResData = [ETRImageEditor cropHiResImage:newUserImage
                                            writeToFile:[_user imageFilePath:YES]];
    
    [ETRServerAPIHelper putImageWithHiResData:hiResData
                                    loResData:loResData
                            completionHandler:^(NSNumber * imageID) {
                                // If the image upload was successful,
                                // a new image ID is given.
                                // If it failed, the temporary image ID stays assigned
                                // and will be reuploaded automatically later on.
                                
                                if ([imageID compare:@(10L)] == NSOrderedDescending) {
                                    // Delete the old files, then set the new ID.
                                    [_user deleteImageFiles];
                                    [_user setImageID:imageID];
                                    [ETRCoreDataHelper saveContext];
                                    
                                    // Store the data in the new files.
                                    [loResData writeToFile:[_user imageFilePath:NO]
                                                atomically:YES];
                                    [hiResData writeToFile:[_user imageFilePath:YES]
                                                atomically:YES];
                                }
                            }];
}

@end
