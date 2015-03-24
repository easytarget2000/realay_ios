//
//  ETRLocalUser.m
//  Realay
//
//  Created by Michel S on 17.02.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRLocalUserManager.h"

#import "ETRAlertViewFactory.h"
#import "ETRAppDelegate.h"
#import "ETRCoreDataHelper.h"
#import "ETRImageEditor.h"
#import "ETRServerAPIHelper.h"
#import "ETRSessionManager.h"
#import "ETRUser.h"

#define kDefsKeyUserID          @"LOCAL_USER_REMOTE_ID"
#define kDefsKeyUserName        @"LOCAL_USER_NAME"
#define kDefsKeyUserImageID     @"LOCAL_USER_IMAGE_ID"
#define kDefsKeyUserStatus      @"LOCAL_USER_STATUS"
#define kDefsKeyUserPhone       @"LOCAL_USER_PHONE"
#define kDefsKeyUserMail        @"LOCAL_USER_MAIL"
#define kDefsKeyUserWeb         @"LOCAL_USER_WEBSITE"
#define kDefsKeyUserFb          @"LOCAL_USER_FACEBOOK"
#define kDefsKeyUserIg          @"LOCAL_USER_INSTAGRAM"
#define kDefsKeyUserTwitter     @"LOCAL_USER_TWITTER"

#define kImageSize              1080
#define kImageSizeSmall         128

static ETRLocalUserManager *sharedInstance = nil;

@implementation ETRLocalUserManager

@synthesize user = _user;

#pragma mark - Factory methods

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
    if (_user) {
        return _user;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Check that the user ID exists.
    NSInteger userID = [defaults integerForKey:kDefsKeyUserID];
    
    // TODO: Check CoreData for this User ID before UserDefaults.
    
    if (userID < 10) {
        return nil;
    }
    
    _user = [ETRCoreDataHelper userWithRemoteID:userID
                          downloadIfUnavailable:YES];
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
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:[_user remoteID] forKey:kDefsKeyUserID];
//    [defaults setObject:[_user name] forKey:kDefsKeyUserName];
//    [defaults setObject:[self status] forKey:kDefsUserStatus];
//    [defaults setObject:[self imageID] forKey:kDefsUserImageID];
    [defaults synchronize];
}

- (BOOL)isLocalUser:(ETRUser *)user {
    if (!user || ![user remoteID] || !_user) {
        return NO;
    } else {
        return [[user remoteID] isEqualToNumber:[_user remoteID]];
    }
}

- (void)setImage:(UIImage *)newUserImage withImageView:(UIImageView *)imageView {
    if (!newUserImage || ![self user]) {
        return;
    }
    
    if (imageView) {
        [imageView setImage:newUserImage];
    }
    
    
    // Temporary image IDs are negative, random values.
    long newImageID = arc4random() * LONG_MIN;
    if (newImageID > 0L) {
        newImageID *= -1L;
    }
    NSLog(@"DEBUG: New local User image ID: %ld", newImageID);
    [_user setImageID:@(newImageID)];
    
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
