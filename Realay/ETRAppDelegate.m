//
//  AppDelegate.m
//  Realay
//
//  Created by Michel on 15/06/15.
//  Copyright © 2015 Easy Target. All rights reserved.
//

#import "ETRAppDelegate.h"

#import "ETRActionManager.h"
#import "ETRBouncer.h"
#import "ETRConversationViewController.h"
#import "ETRLocationManager.h"
#import "ETRDefaultsHelper.h"
#import "ETRReachabilityManager.h"
#import "ETRServerAPIHelper.h"
#import "ETRSessionManager.h"
#import "ETRUIConstants.h"


@implementation ETRAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//     Google Maps API Key:
//    [GMSServices provideAPIKey:@"AIzaSyDiLvq1foJVgVyXaHgYQqFk0Ig9rb4XUSM"];
    
    // Initialise the Reachability and Location Managers, in order to avoid delayed Reachability states later.
    [ETRReachabilityManager sharedManager];
//    [ETRLocationManager sharedManager];
    
    [ETRDefaultsHelper authID];
    
    // Additional GUI setup:
    [[self window] setTintColor:[UIColor whiteColor]];
    
    // Register for background fetches.
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    // Cancel all notifications.
    UILocalNotification *localNotif;
    localNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    
    if (localNotif) {
        [application cancelAllLocalNotifications];
    }
    
    // Prepare the random number generator seeed.
    srand48(time(0));
    
    //    UIStoryboard * storyboard = [[[self window] rootViewController] storyboard];
    //    ETRSessionManager * sessionMan = [ETRSessionManager sharedManager];
    //
    //    if ([sessionMan didBeginSession] && [sessionMan room]) {
    //        ETRConversationViewController * conversationViewController;
    //        conversationViewController = [storyboard instantiateViewControllerWithIdentifier:ETRViewControllerIDConversation];
    //        [conversationViewController setIsPublic:YES];
    //        [[self window] setRootViewController:conversationViewController];
    //        [[self window] makeKeyAndVisible];
    //    } else if ([sessionMan restoreSession]) {
    //        UIViewController * joinViewController = [storyboard instantiateViewControllerWithIdentifier:ETRViewControllerIDJoin];
    //        [[self window] setRootViewController:joinViewController];
    //        [[self window] makeKeyAndVisible];
    //    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    [[ETRActionManager sharedManager] didEnterBackground];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    if ([ETRDefaultsHelper doUpdateRoomListAtLocation:[ETRLocationManager location]]) {
        [ETRServerAPIHelper updateRoomListWithCompletionHandler:nil];
    }
    [[ETRActionManager sharedManager] fetchUpdatesWithCompletionHandler:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Notify the server that the user is leaving.
    [ETRServerAPIHelper endSession];
    
    // Remove unsent messages.
    [ETRDefaultsHelper removePublicMessageInputTexts];
}

#pragma mark -
#pragma mark Fetch

- (void)application:(UIApplication *)application
performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
#ifdef DEBUG
    NSLog(@"Background fetch.");
#endif
    
    if ([[ETRSessionManager sharedManager] didStartSession]) {
        [ETRLocationManager isInSessionRegion];
        
        if ([ETRDefaultsHelper doUpdateRoomListAtLocation:[ETRLocationManager location]]) {
            [ETRServerAPIHelper updateRoomListWithCompletionHandler:nil];
        }
        [[ETRActionManager sharedManager] fetchUpdatesWithCompletionHandler:completionHandler];

    } else {
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "org.eztarget.Realay" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Realay" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL * storeURL;
    storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Realay.sqlite"];
    NSError * error;
    NSString * failureReason = @"There was an error creating or loading the application's saved data.";
    NSDictionary *migration = @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES};
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:migration error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"org.eztarget.Realay" code:9999 userInfo:dict];
        // TODO: Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}


@end
