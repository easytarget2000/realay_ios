//
//  AppDelegate.m
//  Realay
//
//  Created by Michel on 13.09.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import "AppDelegate.h"

#import "ETRLocalUser.h"
#import "ETRSession.h"
#import "ETRRoomListViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Google Maps API Key:
    [GMSServices provideAPIKey:@"AIzaSyBi51VpGsRlkDh7rz-1-cv73DOS7aE_yGA"];
    
    // Additional GUI setup:
    [[self window] setTintColor:[UIColor whiteColor]];
    
    // Try to restore the local user from user defaults:
    [[ETRLocalUser sharedLocalUser] restoreFromUserDefaults];
    
    // Make the main manager initialize all preference variables.
    [[ETRSession sharedSession] refreshGUIAttributes];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    // Cancel all notifications.
    UILocalNotification *localNotif;
    localNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    
    if (localNotif) {
        [application cancelAllLocalNotifications];
    }
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[ETRSession sharedSession] switchToBackgroundSession];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[ETRSession sharedSession] switchToBackgroundSession];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    // Reload values incase settings were changed.
    [[ETRLocalUser sharedLocalUser] restoreFromUserDefaults];
    //TODO: Update user settings locally and on DB.
    [[ETRSession sharedSession] refreshGUIAttributes];
    [[ETRSession sharedSession] switchToForegroundSession];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[ETRSession sharedSession] switchToForegroundSession];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[ETRSession sharedSession] switchToBackgroundSession];
}

#pragma mark - Fetch

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    [[ETRSession sharedSession] tick];
    
}

@end
