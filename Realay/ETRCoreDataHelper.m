//
//  ETRJSONCoreDataConnection.m
//  Realay
//
//  Created by Michel on 02/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRCoreDataHelper.h"

#import "ETRAppDelegate.h"
#import "ETRLocalUserManager.h"
#import "ETRRoom.h"
#import "ETRUser.h"

#define kRoomEntityName     @"ETRRoom"
#define kRemoteIDKey        @"remoteID"
#define kRoomDistanceKey    @"queryDistance"
#define kUserEntityName     @"ETRUser"

@interface ETRCoreDataHelper()

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) NSEntityDescription *roomEntity;

@property (strong, nonatomic) NSEntityDescription *userEntity;

@end

@implementation ETRCoreDataHelper

@synthesize managedObjectContext = _managedObjectContext;
@synthesize roomEntity = _roomEntity;
@synthesize userEntity = _userEntity;

#pragma mark -
#pragma mark Accessories

+ (ETRCoreDataHelper *)helper {
    ETRCoreDataHelper *coreDataBridge = [[ETRCoreDataHelper alloc] init];
    ETRAppDelegate *app = (ETRAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [app managedObjectContext];
    if (!context) return coreDataBridge;
    
    [coreDataBridge setManagedObjectContext:context];
    
    return coreDataBridge;
}

- (BOOL)saveContext {
    // Save Record.
    NSError *error;
    if (![_managedObjectContext save:&error] || error) {
        NSLog(@"ERROR: Could not save context: %@", error);
        return true;
    } else {
        return false;
    }
}

#pragma mark -
#pragma mark Rooms

- (void)insertRoomFromDictionary:(NSDictionary *)JSONDict {
    if (!_managedObjectContext) return;
    
    if (!_roomEntity) {
        _roomEntity = [NSEntityDescription entityForName:kRoomEntityName inManagedObjectContext:_managedObjectContext];
    }
    
    // Get the remote DB ID from the JSON data.
    NSNumber *remoteID = [NSNumber numberWithLong:[[JSONDict objectForKey:@"r"] longLongValue]];
    
    // Check the context CoreData, if an object with this remote ID already exists.
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:kRoomEntityName];
    NSString *where = [NSString stringWithFormat:@"%@ == %ld", kRemoteIDKey, [remoteID longValue]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:where];
    [fetch setPredicate:predicate];
    NSArray *existingRooms = [_managedObjectContext executeFetchRequest:fetch error:nil];
    
    ETRRoom *room;
    if (existingRooms && [existingRooms count]) {
        if ([existingRooms[0] isKindOfClass:[ETRRoom class]]) {
            room = (ETRRoom *)existingRooms[0];
        }
    }
    
    if (!room) {
        room = [[ETRRoom alloc] initWithEntity:_roomEntity insertIntoManagedObjectContext:_managedObjectContext];
        [room setRemoteID:remoteID];
    }

    [room setImageID:@((long) [[JSONDict objectForKey:@"i"] longLongValue])];
    NSString *radius = (NSString *)[JSONDict objectForKey:@"rd"];
    [room setRadius:@((short) [radius integerValue])];
    NSString *userCount = (NSString *)[JSONDict objectForKey:@"ucn"];
    [room setQueryUserCount:@((short) [userCount integerValue])];
    
    [room setTitle:(NSString *)[JSONDict objectForKey:@"tt"]];
    [room setSummary:(NSString *)[JSONDict objectForKey:@"ds"]];
    [room setPassword:(NSString *)[JSONDict objectForKey:@"pw"]];
    if ([[JSONDict objectForKey:@"ad"] isMemberOfClass:[NSString class]]) {
        [room setAddress:(NSString *)[JSONDict objectForKey:@"ad"]];
    }
    
    NSInteger startTimestamp = [(NSString *)[JSONDict objectForKey:@"st"] integerValue];
    if (startTimestamp > 1000000000) {
        [room setStartTime:[NSDate dateWithTimeIntervalSince1970:startTimestamp]];
    }
    
    NSInteger endTimestamp = [(NSString *)[JSONDict objectForKey:@"et"] integerValue];
    if (endTimestamp > 1000000000) {
        [room setEndDate:[NSDate dateWithTimeIntervalSince1970:startTimestamp]];
    }
    
    // We query the database with km values and only use metre integer precision.
    NSString *distance = (NSString *)[JSONDict objectForKey:@"dst"];
    [room setQueryDistance:@([distance integerValue] * 1000)];
    NSString *latitude = (NSString *)[JSONDict objectForKey:@"lat"];
    [room setLatitude:@([latitude floatValue])];
    NSString *longitude = (NSString *)[JSONDict objectForKey:@"lng"];
    [room setLongitude:@([longitude floatValue])];
    
    NSLog(@"Inserting Room: %@", [room description]);
    [self saveContext];
}

- (NSFetchedResultsController *)roomListResultsControllerWithDelegate:(id<NSFetchedResultsControllerDelegate>) delegate {
    if (!_managedObjectContext) return nil;
    
    // Initialize Fetch Request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kRoomEntityName];
    
    // Add Sort Descriptors
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:kRoomDistanceKey ascending:YES]]];
    
    // Initialize Fetched Results Controller
    NSFetchedResultsController *resultsController;
    resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                   managedObjectContext:_managedObjectContext
                                                                     sectionNameKeyPath:nil
                                                                              cacheName:nil];
    
    // Configure Fetched Results Controller
    [resultsController setDelegate:delegate];
    return resultsController;
}

- (ETRRoom *)roomWithRemoteID:(long)remoteID {
    return nil;
}

#pragma mark -
#pragma mark Actions

- (void)handleMessageInDictionary:(NSDictionary *)jsonDictionary {
    
}

#pragma mark -
#pragma mark User Objects

- (ETRUser *)insertUserFromDictionary:(NSDictionary *)jsonDictionary {
    if (!_managedObjectContext) {
        NSLog(@"ERROR: No Managed Object Context to insert User into.");
        return nil;
    }
    
    // Get the remote DB ID from the JSON data.
    long remoteID = [jsonDictionary longValueForKey:@"u" withFallbackValue:-55];
    
    if (remoteID < 10) {
        NSLog(@"ERROR: Could not insert User because remote ID is invalid: %ld", remoteID);
        return nil;
    }
    
    // Check the context CoreData, if an object with this remote ID already exists.
    ETRUser *user = [self userWithRemoteID:remoteID];
    
    if (!user) {
        // The User was not stored in the local database yet, use the CoreData initializer to create a new object.
        if (!_userEntity) {
            _userEntity = [NSEntityDescription entityForName:kUserEntityName
                                      inManagedObjectContext:_managedObjectContext];
        }
        user = [[ETRUser alloc] initWithEntity:_userEntity
                insertIntoManagedObjectContext:_managedObjectContext];
        [user setRemoteID:@(remoteID)];
    }
    
    [user setImageID:@([jsonDictionary longValueForKey:@"i" withFallbackValue:-5])];
    [user setName:[jsonDictionary stringForKey:@"n"]];
    [user setStatus:[jsonDictionary stringForKey:@"s"]];
    [user setMail:[jsonDictionary stringForKey:@"em"]];
    [user setPhone:[jsonDictionary stringForKey:@"ph"]];
    [user setWebsite:[jsonDictionary stringForKey:@"ws"]];
    [user setFacebook:[jsonDictionary stringForKey:@"fb"]];
    [user setInstagram:[jsonDictionary stringForKey:@"ig"]];
    [user setTwitter:[jsonDictionary stringForKey:@"tw"]];
    
//    NSLog(@"Inserting User: %@", [user description]);
    [self saveContext];
    return user;
}

- (ETRUser *)copyUser:(ETRUser *)user {
    if (!user || !_managedObjectContext) {
        return nil;
    }
    
    ETRUser *copiedUser;
    if (!_userEntity) {
        _userEntity = [NSEntityDescription entityForName:kUserEntityName
                                  inManagedObjectContext:_managedObjectContext];
    }
    copiedUser = [[ETRUser alloc] initWithEntity:_userEntity
                  insertIntoManagedObjectContext:_managedObjectContext];
    
    // Copy all the attributes.
    [copiedUser setRemoteID:[user remoteID]];
    [copiedUser setImageID:[user imageID]];
    [copiedUser setName:[user name]];
    [copiedUser setStatus:[user status]];
    [copiedUser setPhone:[user phone]];
    [copiedUser setMail:[user mail]];
    [copiedUser setWebsite:[user website]];
    [copiedUser setFacebook:[user facebook]];
    [copiedUser setInstagram:[user instagram]];
    [copiedUser setTwitter:[user twitter]];
    
    // This user will not be stored.
    return copiedUser;
}

- (ETRUser *)userWithRemoteID:(long)remoteID {
    if (!_managedObjectContext) {
        return nil;
    }
    
    // Check the context CoreData, if an object with this remote ID exists.
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:kUserEntityName];
    NSString *where = [NSString stringWithFormat:@"%@ == %ld", kRemoteIDKey, remoteID];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:where];
    [fetch setPredicate:predicate];
    NSArray *existingUsers = [_managedObjectContext executeFetchRequest:fetch error:nil];
    
    if (existingUsers && [existingUsers count]) {
        if ([existingUsers[0] isKindOfClass:[ETRUser class]]) {
            return (ETRUser *)existingUsers[0];
        }
    }
    
    return nil;
}

@end

@implementation NSDictionary (TypesafeJSON)

- (NSString *)stringForKey:(id)key {
    id object = [self objectForKey:key];
    
    if (object && [object isKindOfClass:[NSString class]]) {
        return (NSString *)object;
    } else {
        return nil;
    }
}

- (long)longValueForKey:(id)key withFallbackValue:(long)fallbackValue {
    NSString *value = [self stringForKey:key];
    if (value) {
        return (long) [value longLongValue];
    } else {
        return fallbackValue;
    }
}

- (short)shortValueForKey:(id)key withFallbackValue:(short)fallbackValue {
    NSString *value = [self stringForKey:key];
    if (value) {
        return [value integerValue];
    } else {
        return fallbackValue;
    }
}

@end
