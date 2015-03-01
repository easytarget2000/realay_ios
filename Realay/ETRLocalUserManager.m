//
//  ETRLocalUser.m
//  Realay
//
//  Created by Michel S on 17.02.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRLocalUserManager.h"

#import "ETRAppDelegate.h"
#import "ETRServerAPIHelper.h"
#import "ETRSession.h"

//#import "SharedMacros.h"

#define kDefsKeyUserID          @"userDefaultsUserID"
#define kDefsKeyUserImageID     @"userDefaultsUserImageID"
#define kDefsKeyUserStatus      @"userDefaultsUserStatus"
#define kDefsKeyUserPhone       @"userDefaultsUserPhone"
#define kDefsKeyUserMail        @"userDefaultsUserMail"
#define kDefsKeyUserWeb         @"userDefaultsUserWeb"
#define kDefsKeyUserFb          @"userDefaultsUserFb"
#define kDefsKeyUserIg          @"userDefaultsUserIg"
#define kDefsKeyUserTwitter     @"userDefaultsUserTwitter"

#define kImageSize              1080
#define kImageSizeSmall         128

#define kInsertUserCall         @"insert_user"
#define kUpdateUserCall         @"update_user"

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

- (User *)user {
    if (_user) return _user;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Check that the user ID exists.
    NSInteger userID = [defaults integerForKey:kDefsKeyUserID];
    
    // TODO: Check CoreData for this User ID before UserDefaults.
    
    if (userID > 10) {
        
        
//        _user = [ETRUser ]
//        
//        [user setUserID:userID];
//        [self setName:[defaults objectForKey:kDefsKeyUserName]];
//        [self setStatus:[defaults objectForKey:kDefsKeyUserStatus]];
//        [self setImageID:[defaults objectForKey:kDefsKeyUserImageID]];
//        [self setMail:[defaults object]]
        
        
    } else  {
        NSLog(@"ERROR: LocalUser object not in user defaults.");
    }
    
    return _user;
}

- (void)setUser:(User *)user {
    if (!user) return;
    [self setUser:user];
    [self storeData];
}

- (long)userID {
    if (![self user]) return -34;
    
    return [[[self user] remoteID] longValue];
}
    
//    [self setName:name];
//    [self setStatus:@"Hi!"];
//    [self setDeviceId:kNewDefaultDeviceId];
//    [self setUserID:-1];
//    
//    NSString *bodyString = [NSString stringWithFormat:@"device_id=%@&name=%@",
//                            [self deviceId], [self name]];
//    
//    // Get the JSON data and parse it.
//    NSDictionary *jsonDict = [ETRHTTPHandler JSONDictionaryFromPHPScript:kPHPInsertUser bodyString:bodyString];
//    NSString *statusCode = [jsonDict valueForKey:@"status"];
//    
//    NSInteger receivedID = -1;
//    
//    if (![statusCode isEqualToString:@"INSERT_USER_OK"]) {
//        NSLog(@"ERROR: %@", statusCode);
//        return NO;
//    } else {
//        receivedID = [[jsonDict valueForKey:@"new_id"] intValue];
//    }
//    
//#ifdef DEBUG
//    NSLog(@"INFO: idFromInsertUser returns %ld", receivedID);
//#endif
//    
//    if (receivedID < 1) return NO;
//    else [self setUserID:receivedID];
//    
//#ifdef DEBUG
//    NSLog(@"INFO: Stored new user in database with ID %ld", receivedID);
//#endif
//    
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setInteger:[self userID] forKey:kUserDefKeyUserID];
//    [defaults setObject:[self name] forKey:kDefsUserName];
//    [defaults setObject:[self status] forKey:kDefsUserStatus];
//    [defaults setObject:[self imageID] forKey:kDefsUserImageID];
//    [defaults synchronize];

- (BOOL)storeData {
    ETRAppDelegate *app = (ETRAppDelegate *)[[UIApplication sharedApplication] delegate];
    [[app managedObjectContext] insertObject:[self user]];

    return YES;
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

@end
