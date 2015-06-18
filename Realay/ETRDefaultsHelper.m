//
//  ETRPreferenceHelper.m
//  Realay
//
//  Created by Michel on 15/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRDefaultsHelper.h"

#import <CoreLocation/CoreLocation.h>

#import "ETRCoreDataHelper.h"
#import "ETRRoom.h"


static NSString *const ETRDefaultsKeyAuthID = @"auth_id";

static NSString *const ETRDefaultsKeyAuthDialogs = @"auth_dialogs";

static NSString *const ETRDefaultsKeyDidRunOnce = @"did_run";

static NSString *const ETRDefaultsKeyInputTexts = @"input_texts";

static NSString *const ETRDefaultsKeyLastUpdateAccuracy = @"last_update_accuracy";

static NSString *const ETRDefaultsKeyLastUpdateAlt = @"last_update_alt";

static NSString *const ETRDefaultsKeyLastUpdateLat = @"last_update_lat";

static NSString *const ETRDefaultsKeyLastUpdateLng = @"last_update_lng";

static NSString *const ETRDefaultsKeyLastUpdateTime = @"last_update_time";

static NSString *const ETRdefaultsKeyNotificationsOther = @"notifications_other";

static NSString *const ETRDefaultsKeyNotificationsPublic = @"notifications_public";

static NSString *const ETRDefaultsKeyNotificationsPrivate = @"notifications_private";

static NSString *const ETRDefaultsKeySession = @"session_r";

static NSString *const ETRDefaultsKeyUserID = @"local_user";

static CFTimeInterval const ETRRoomListUpdateInterval = 20.0 * 60.0;

static CLLocationDistance const ETRRoomListUpdateDistance = 500.0;

static CLLocation * LastUpdateLocation;


@implementation ETRDefaultsHelper

#pragma mark -
#pragma mark General

+ (BOOL)didRunOnce {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    BOOL didRunOnce = [defaults boolForKey:ETRDefaultsKeyDidRunOnce];
    if (!didRunOnce) {
        [defaults setBool:YES forKey:ETRDefaultsKeyDidRunOnce];
        [defaults synchronize];
        return NO;
    } else {
        return YES;
    }
}

+ (BOOL)didShowAuthorizationDialogs{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:ETRDefaultsKeyAuthDialogs];
}

+ (void)acknowledgeAuthorizationDialogs {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:ETRDefaultsKeyAuthDialogs];
    [defaults synchronize];
}

+ (NSNumber *)localUserID {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:ETRDefaultsKeyUserID];
}

+ (void)storeLocalUserID:(NSNumber *)remoteID {
    if (!remoteID || [remoteID longValue] < 100L) {
        return;
    }
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:remoteID forKey:ETRDefaultsKeyUserID];
    [defaults synchronize];
}

+ (NSString *)authID {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    
    // Check that the user ID exists.
    NSString * userID = [defaults stringForKey:ETRDefaultsKeyAuthID];
    
    if (!userID) {
        if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
            // IOS 6 new Unique Identifier implementation, IFA
            userID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        } else {
            userID = [NSString stringWithFormat:@"%@-%ld", [[UIDevice currentDevice] systemVersion], random()];
        }
        
        [defaults setObject:userID forKey:ETRDefaultsKeyAuthID];
        [defaults synchronize];
    }
    
    return userID;
}

#pragma mark -
#pragma mark Settings

+ (BOOL)doUseMetricSystem {
    // TODO: Read from Settings.
    
    NSLocale * locale = [NSLocale currentLocale];
    
    id localeMeasurement = [locale objectForKey:NSLocaleUsesMetricSystem];
    if (localeMeasurement && [localeMeasurement isKindOfClass:[NSNumber class]]) {
        return [localeMeasurement boolValue];
    }
    
    return YES;
}

+ (BOOL)doShowPrivateNotifs {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:ETRDefaultsKeyNotificationsPrivate];
}

+ (BOOL)doShowPublicNotifs {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:ETRDefaultsKeyNotificationsPublic];
}

#pragma mark -
#pragma mark Location & Room Updates

+ (BOOL)doUpdateRoomListAtLocation:(CLLocation *)location {
    if (!location) {
        return NO;
    }
    
    if (![ETRDefaultsHelper lastUpdateLocation]) {
#ifdef DEBUG
        NSLog(@"Updating Rooms. No update Location can be found.");
#endif
        return YES;
    }
    
    CFTimeInterval lastUpdateInterval = [[LastUpdateLocation timestamp] timeIntervalSinceNow];
    if (lastUpdateInterval > ETRRoomListUpdateInterval) {
#ifdef DEBUG
        NSLog(@"Updating Rooms. Last Update was %g s ago.", lastUpdateInterval);
#endif
        return YES;
    }
    
    CLLocationDistance lastUpdateDistance = [LastUpdateLocation distanceFromLocation:location];
    if (lastUpdateDistance > ETRRoomListUpdateDistance) {
#ifdef DEBUG
        NSLog(@"Updating Rooms. Last Update was %g m away.", lastUpdateDistance);
#endif
        return YES;
    }
    
    return NO;
}

+ (CLLocation *)lastUpdateLocation {
    if (!LastUpdateLocation) {
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        CFAbsoluteTime lastUpdateTime = [defaults doubleForKey:ETRDefaultsKeyLastUpdateTime];
        if (lastUpdateTime != 0.0) {
            if (CFAbsoluteTimeGetCurrent() - lastUpdateTime > ETRRoomListUpdateInterval) {
                return nil;
            }
        } else {
            return nil;
        }
        
        CLLocationDegrees latitude = [defaults doubleForKey:ETRDefaultsKeyLastUpdateLat];
        if (latitude == 0.0) {
            return nil;
        }
        
        CLLocationDegrees longitude = [defaults doubleForKey:ETRDefaultsKeyLastUpdateLng];
        if (longitude == 0.0) {
            return nil;
        }
        
        CLLocationCoordinate2D coordinate;
        coordinate.latitude = latitude;
        coordinate.longitude = longitude;
        
        CLLocationDistance altitude = [defaults doubleForKey:ETRDefaultsKeyLastUpdateAlt];
        
        CLLocationAccuracy accuracy = [defaults doubleForKey:ETRDefaultsKeyLastUpdateAccuracy];
        if (accuracy == 0.0) {
            return nil;
        }
        
        LastUpdateLocation = [[CLLocation alloc] initWithCoordinate:coordinate
                                                           altitude:altitude
                                                 horizontalAccuracy:accuracy
                                                   verticalAccuracy:accuracy
                                                          timestamp:[NSDate date]];
    }
    return LastUpdateLocation;
}

+ (void)acknowledgeRoomListUpdateAtLocation:(CLLocation *)location {
    if (!location) {
        return;
    }
    
    // The Location will be used to check when to update the Room list next
    // and also as a backup Location.
    LastUpdateLocation = location;
    
    // Store the Location in the User Defaults.
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setDouble:[location altitude] forKey:ETRDefaultsKeyLastUpdateAlt];
    [defaults setDouble:location.coordinate.latitude forKey:ETRDefaultsKeyLastUpdateLat];
    [defaults setDouble:location.coordinate.longitude forKey:ETRDefaultsKeyLastUpdateLng];
    
    CFAbsoluteTime time = [[location timestamp] timeIntervalSinceReferenceDate];
    [defaults setDouble:time forKey:ETRDefaultsKeyLastUpdateTime];
    
    // Store the larger Accuracy.
    if ([location horizontalAccuracy] > [location verticalAccuracy]) {
        [defaults setDouble:[location horizontalAccuracy] forKey:ETRDefaultsKeyLastUpdateAccuracy];
    } else {
        [defaults setDouble:[location verticalAccuracy] forKey:ETRDefaultsKeyLastUpdateAccuracy];
    }
    
    [defaults synchronize];
}


#pragma mark -
#pragma mark Session Persistence

+ (ETRRoom *)restoreSession {
    id<NSObject> storedRoom = [[NSUserDefaults standardUserDefaults] objectForKey:ETRDefaultsKeySession];
    if (storedRoom && [storedRoom isKindOfClass:[NSNumber class]]) {
        return [ETRCoreDataHelper roomWithRemoteID:(NSNumber *) storedRoom];
    } else {
        return nil;
    }
}

+ (void)storeSession:(NSNumber *)sessionID {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:sessionID forKey:ETRDefaultsKeySession];
    [defaults synchronize];
}

+ (void)removeSession {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:ETRDefaultsKeySession];
    [defaults synchronize];
}

+ (NSString *)messageInputTextForConversationID:(NSNumber *)conversationID {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary * storedTexts = [defaults objectForKey:ETRDefaultsKeyInputTexts];
    if (storedTexts) {
       id<NSObject> storedText = [storedTexts objectForKey:[conversationID stringValue]];
        if (storedText && [storedText isKindOfClass:[NSString class]]) {
            return (NSString *)storedText;
        }
    }
    
    return @"";
}

+ (void)storeMessageInputText:(NSString *)inputText
            forConversationID:(NSNumber *)conversationID {
    
    if (!inputText || !conversationID) {
        return;
    }
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    
    NSDictionary * storedTexts = [defaults objectForKey:ETRDefaultsKeyInputTexts];
    if (!storedTexts) {
        storedTexts = [NSMutableDictionary dictionary];
    }
    
    NSMutableDictionary * newTexts = [NSMutableDictionary dictionaryWithDictionary:storedTexts];
    [newTexts setObject:inputText forKey:[conversationID stringValue]];
    
    [defaults setObject:newTexts forKey:ETRDefaultsKeyInputTexts];
    [defaults synchronize];
}

+ (void)removePublicMessageInputTexts{
    [ETRDefaultsHelper storeMessageInputText:@"" forConversationID:@(ETRActionPublicUserID)];
    
//    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
//    NSMutableDictionary * storedTexts = [defaults objectForKey:ETRDefaultsKeyInputTexts];
//    if (storedTexts) {
//        [storedTexts setObject:nil forKey:[@(ETRActionPublicUserID) stringValue]];
//    }
//    [defaults synchronize];
}


@end
