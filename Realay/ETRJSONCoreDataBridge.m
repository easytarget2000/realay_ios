//
//  ETRJSONCoreDataConnection.m
//  Realay
//
//  Created by Michel on 02/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRJSONCoreDataBridge.h"

#import "ETRAppDelegate.h"
#import "ETRRoom.h"

#define kRoomEntityName     @"ETRRoom"
#define kRemoteIDKey        @"remoteID"
#define kRoomDistanceKey    @"queryDistance"

@interface ETRJSONCoreDataBridge()

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSEntityDescription *roomEntity;

@end

@implementation ETRJSONCoreDataBridge

@synthesize managedObjectContext = _managedObjectContext;
@synthesize roomEntity = _roomEntity;

+ (ETRJSONCoreDataBridge *)coreDataBridge {
    ETRJSONCoreDataBridge *coreDataBridge = [[ETRJSONCoreDataBridge alloc] init];
    ETRAppDelegate *app = (ETRAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [app managedObjectContext];
    if (!context) return coreDataBridge;
    
    [coreDataBridge setManagedObjectContext:context];
    
    return coreDataBridge;
}

- (void)insertRoomFromDictionary:(NSDictionary *)JSONDict {
    if (!_managedObjectContext) return;
    
    if (!_roomEntity) {
        _roomEntity = [NSEntityDescription entityForName:kRoomEntityName inManagedObjectContext:_managedObjectContext];
    }
    
    // Get the remote DB ID from the JSON data.
    NSNumber *remoteID = [NSNumber numberWithLong:[[JSONDict objectForKey:@"r"] longLongValue]];
    
    // Check the context CoreData, if an object with this remote ID already exists.
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:kRoomEntityName];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%@ == %@", kRemoteIDKey, remoteID];
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
        [room setEndTime:[NSDate dateWithTimeIntervalSince1970:startTimestamp]];
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

- (void)saveContext {
    // Save Record.
    NSError *error;
    if (![_managedObjectContext save:&error] || error) {
        NSLog(@"ERROR: Could not save context: %@", error);
    }
}

@end
