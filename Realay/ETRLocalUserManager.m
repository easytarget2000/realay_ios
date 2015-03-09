//
//  ETRLocalUser.m
//  Realay
//
//  Created by Michel S on 17.02.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRLocalUserManager.h"

#import "ETRAppDelegate.h"
#import "ETRCoreDataHelper.h"
#import "ETRServerAPIHelper.h"
#import "ETRSession.h"
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
    
    _user = [[ETRCoreDataHelper helper] userWithRemoteID:userID];
    if (_user) {
        return _user;
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

- (long)userID {
    if (![self user]) return -34;
    
    return [[[self user] remoteID] longValue];
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

- (void)updateImage:(UIImage *)image {
    
    // Only resize and crop to a useful square, if the size is not quite right.
    if (image.size.width != kImageSize && image.size.height != kImageSize) {
        
        // Fit the cropped image into the standard size.
        UIGraphicsBeginImageContextWithOptions((CGSizeMake(kImageSize, kImageSize)), NO, 0);
        [image drawInRect:CGRectMake(0, 0, kImageSize, kImageSize)];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    // Follow the same procedure for the smaller, preview image.
    UIImage *smallImage;
    if (image.size.width != kImageSizeSmall && image.size.height != kImageSizeSmall) {
        // Fit the cropped image into the standard size.
        UIGraphicsBeginImageContextWithOptions((CGSizeMake(kImageSizeSmall, kImageSizeSmall)), NO, 0);
        [image drawInRect:CGRectMake(0, 0, kImageSizeSmall, kImageSizeSmall)];
        smallImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    // Prepare the URL to the download script.
    NSString *URLString;
    NSURL *URL = [NSURL URLWithString:URLString];
    
    // Prepare the POST request.
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"POST"];
//    [request setTimeoutInterval:kHTTPTimeout];
    [request setURL:URL];
    
    // Build a multi-field POST HTTP request.
    NSString *boundary = @"0xKhTmLbOuNdArY";
    NSString *boundaryReturned = [NSString stringWithFormat:@"\r\n--%@\r\n",boundary];
    // Header:
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *bodyData = [NSMutableData data];
    [bodyData appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    // The big image:
    [bodyData appendData:[@"Content-Disposition: form-data; name=\"userfile\"; filename=\"upimg.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [bodyData appendData:[@"Content-Type: image/jpg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [bodyData appendData:[NSData dataWithData:UIImageJPEGRepresentation(image, 0.9f)]];
    [bodyData appendData:[boundaryReturned dataUsingEncoding:NSUTF8StringEncoding]];
    // The preview image:
    [bodyData appendData:[@"Content-Disposition: form-data; name=\"userfile_s\"; filename=\"upimgs.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [bodyData appendData:[@"Content-Type: image/jpg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [bodyData appendData:[NSData dataWithData:UIImageJPEGRepresentation(smallImage, 0.7f)]];
    [bodyData appendData:[boundaryReturned dataUsingEncoding:NSUTF8StringEncoding]];

#ifdef DEBUG
    NSLog(@"INFO: User image upload started.");
#endif
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data,
                                               NSError *connectionError) {
                               
                               if (connectionError) {
                                   NSLog(@"ERROR: %@", connectionError);
                               }
                               
                               NSLog(@"INFO: upload_image returns: %@",
                                     [NSString stringWithUTF8String:[data bytes]]);
                           }];
}

- (BOOL)isLocalUser:(ETRUser *)user {
    if (!user || ![user remoteID] || !_user) {
        return NO;
    } else {
        return [[user remoteID] isEqualToNumber:[_user remoteID]];
    }
}

@end
