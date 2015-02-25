//
//  ETRLocalUser.m
//  Realay
//
//  Created by Michel S on 17.02.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRLocalUser.h"

#import "ETRHTTPHandler.h"
#import "ETRSession.h"

#import "SharedMacros.h"

#define kNewDefaultDeviceId     @"UNKNOWN_DEVICE_ID"
#define kUserDefKeyUserID       @"userDefaultsUserID"
#define kUserDefsUserImageID    @"userDefaultsUserImageID"

#define kImageSize              1080
#define kImageSizeSmall         128

#define kPHPInsertUser          @"insert_user.php"
#define kPHPUpdateUser          @"update_user.php"

static ETRLocalUser *sharedInstance = nil;

@implementation ETRLocalUser

#pragma mark - Factory methods

+ (void)initialize {
    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        sharedInstance = [[ETRLocalUser alloc] init];
    }
}

+ (ETRLocalUser *)sharedLocalUser {
    return sharedInstance;
}

- (void)restoreFromUserDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
//    [defaults setObject:kUserTestImageURL forKey:kUserDefsUserIconUrl];
//    [defaults synchronize];
    
    // Check that the user ID exists.
    NSInteger userID = [defaults integerForKey:kUserDefKeyUserID];
    if (userID > 0) {
        [self setUserID:userID];
        [self setName:[defaults objectForKey:kUserDefsUserName]];
        [self setStatus:[defaults objectForKey:kUserDefsUserStatus]];
        [self setImageID:[defaults objectForKey:kUserDefsUserImageID]];
        [self setImage:[ETRHTTPHandler downloadImageWithID:[self imageID]]];
    } else  {
        [self setUserID:-2];
        NSLog(@"ERROR: LocalUser object not in user defaults.");
    }
}

- (BOOL)insertNewLocalUserWithName:(NSString *)name {
    [self setName:name];
    [self setStatus:@"Hi!"];
    [self setDeviceId:kNewDefaultDeviceId];
    [self setUserID:-1];
    
    NSString *bodyString = [NSString stringWithFormat:@"device_id=%@&name=%@",
                            [self deviceId], [self name]];
    
    // Get the JSON data and parse it.
    NSDictionary *jsonDict = [ETRHTTPHandler JSONDictionaryFromPHPScript:kPHPInsertUser bodyString:bodyString];
    NSString *statusCode = [jsonDict valueForKey:@"status"];
    
    NSInteger receivedID = -1;
    
    if (![statusCode isEqualToString:@"INSERT_USER_OK"]) {
        NSLog(@"ERROR: %@", statusCode);
        return NO;
    } else {
        receivedID = [[jsonDict valueForKey:@"new_id"] intValue];
    }
    
#ifdef DEBUG
    NSLog(@"INFO: idFromInsertUser returns %ld", receivedID);
#endif
    
    if (receivedID < 1) return NO;
    else [self setUserID:receivedID];
    
#ifdef DEBUG
    NSLog(@"INFO: Stored new user in database with ID %ld", receivedID);
#endif
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:[self userID] forKey:kUserDefKeyUserID];
    [defaults setObject:[self name] forKey:kUserDefsUserName];
    [defaults setObject:[self status] forKey:kUserDefsUserStatus];
    [defaults setObject:[self imageID] forKey:kUserDefsUserImageID];
    [defaults synchronize];
    
    return YES;
}

#pragma mark - Database Modifications

- (BOOL)wasAbleToUpdateUser {

    // Build the URL GET string.
    NSString *bodyString = [NSString stringWithFormat:@"user_id=%ld&name=%@&status=%@",
                            [self userID], [self name], [self status]];
    
    // Get the JSON data and parse it.
    NSDictionary *requestJSON = [ETRHTTPHandler JSONDictionaryFromPHPScript:kPHPUpdateUser
                                                                 bodyString:bodyString];
    NSString *statusCode = [requestJSON valueForKey:@"status"];
    
    // If an error returned, stop here.
    if(![statusCode isEqualToString:@"UPDATE_USER_OK"]) {
        NSLog(@"ERROR: %@", statusCode);
        return NO;
    }
    
    // Update the user defaults.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self name] forKey:kUserDefsUserName];
    [defaults setObject:[self status] forKey:kUserDefsUserStatus];
    [defaults synchronize];
    
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
    [self setImage:image];
    
    // Follow the same procedure for the smaller, preview image.
    UIImage *smallImage;
    if (image.size.width != kImageSizeSmall && image.size.height != kImageSizeSmall) {
        
        // Fit the cropped image into the standard size.
        UIGraphicsBeginImageContextWithOptions((CGSizeMake(kImageSizeSmall, kImageSizeSmall)), NO, 0);
        [image drawInRect:CGRectMake(0, 0, kImageSizeSmall, kImageSizeSmall)];
        smallImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [self setImage:smallImage];
    } else {
        [self setImage:image];
    }
    
    // Prepare the URL to the download script.
    NSString *URLString = [NSString stringWithFormat:@"%@%@",
                           kURLPHPScripts, kPHPUploadImage];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    // Prepare the POST request.
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:kHTTPTimeout];
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
    [bodyData appendData:[NSData dataWithData:UIImageJPEGRepresentation([self image], .7)]];
    [bodyData appendData:[boundaryReturned dataUsingEncoding:NSUTF8StringEncoding]];
    // The preview image:
    [bodyData appendData:[@"Content-Disposition: form-data; name=\"userfile_s\"; filename=\"upimgs.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [bodyData appendData:[@"Content-Type: image/jpg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [bodyData appendData:[NSData dataWithData:UIImageJPEGRepresentation([self smallImage], .7)]];
    [bodyData appendData:[boundaryReturned dataUsingEncoding:NSUTF8StringEncoding]];
    // image_id:
    [bodyData appendData:[@"Content-Disposition: form-data; name=\"image_id\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [bodyData appendData:[[self imageID] dataUsingEncoding:NSUTF8StringEncoding]];
    [bodyData appendData:[boundaryReturned dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:bodyData];


#ifdef DEBUG
    NSLog(@"INFO: User image upload started: %@", [self imageID]);
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
