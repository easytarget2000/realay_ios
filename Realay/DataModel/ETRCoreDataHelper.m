//
//  ETRJSONCoreDataConnection.m
//  Realay
//
//  Created by Michel on 02/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRCoreDataHelper.h"

#import "ETRAction.h"
#import "ETRActionManager.h"
#import "ETRAppDelegate.h"
#import "ETRConversation.h"
#import "ETRImageEditor.h"
#import "ETRLocalUserManager.h"
#import "ETRRoom.h"
#import "ETRServerAPIHelper.h"
#import "ETRSessionManager.h"
#import "ETRUser.h"


long const ETRActionPublicUserID = -10;

static NSString *const ETRRemoteIDKey = @"remoteID";

static NSString *const ETRRoomDistanceKey = @"queryDistance";

static NSString *const ETRActionCodeKey = @"code";

static NSString *const ETRActionSenderKey = @"sender";

static NSString *const ETRActionRecipientKey = @"recipient";

static NSString *const ETRActionDateKey = @"sentDate";

static NSString *const ETRActionRoomKey = @"room";

static NSString *const ETRConversationPartnerKey = @"partner";

static NSString *const ETRInRoomKey = @"inRoom";

static NSString *const ETRUserNameKey = @"name";

static NSString *const ETRUserIsBlockedKey = @"isBlocked";

static NSManagedObjectContext * ManagedObjectContext;

static NSEntityDescription * ActionEntity;

static NSString * ActionEntityName;

static NSEntityDescription * ConversationEntity;

static NSString * ConversationEntityName;

static NSEntityDescription * RoomEntity;

static NSString * RoomEntityName;

static NSEntityDescription * UserEntity;

static NSString * UserEntityName;


@implementation ETRCoreDataHelper

#pragma mark -
#pragma mark Accessories

+ (NSManagedObjectContext *)context {
    if (!ManagedObjectContext) {
        ETRAppDelegate *app = (ETRAppDelegate *) [[UIApplication sharedApplication] delegate];
        ManagedObjectContext = [app managedObjectContext];
    }
    return ManagedObjectContext;
}

+ (NSEntityDescription *)roomEntity {
    if (!RoomEntity) {
        RoomEntity = [NSEntityDescription entityForName:[ETRCoreDataHelper roomEntityName]
                                 inManagedObjectContext:[ETRCoreDataHelper context]];
    }
    return RoomEntity;
}

+ (NSString *)roomEntityName {
    if (!RoomEntityName) {
        RoomEntityName = NSStringFromClass([ETRRoom class]);
    }
    return RoomEntityName;
}

+ (NSEntityDescription *)userEntity {
    if (!UserEntity) {
        UserEntity = [NSEntityDescription entityForName:[ETRCoreDataHelper userEntityName]
                                 inManagedObjectContext:[ETRCoreDataHelper context]];
    }
    return UserEntity;
}

+ (NSString *)userEntityName {
    if (!UserEntityName) {
        UserEntityName = NSStringFromClass([ETRUser class]);
    }
    return UserEntityName;
}

#pragma mark -
#pragma mark General Context Accessories

+ (BOOL)saveContext {
    // Save Record.
    NSError * error;
    if (![[ETRCoreDataHelper context] save:&error]) {
        NSLog(@"ERROR: Could not save context: %@", error);
        return false;
    } else {
        return true;
    }
}

+ (void)deleteObject:(nonnull NSManagedObject *)object {
    [[ETRCoreDataHelper context] deleteObject:object];
}

#pragma mark -
#pragma mark Actions

+ (NSEntityDescription *)actionEntity {
    if (!ActionEntity) {
        ActionEntity = [NSEntityDescription entityForName:[ETRCoreDataHelper actionEntityName]
                                   inManagedObjectContext:[ETRCoreDataHelper context]];
    }
    return ActionEntity;
}

+ (NSString *)actionEntityName {
    if (!ActionEntityName) {
        ActionEntityName = NSStringFromClass([ETRAction class]);
    }
    return ActionEntityName;
}

+ (ETRAction *)actionWithRemoteID:(long)remoteID {
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:[ETRCoreDataHelper actionEntityName]];
    NSString *where = [NSString stringWithFormat:@"%@ == %ld", ETRRemoteIDKey, remoteID];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:where];
    [fetch setPredicate:predicate];
    NSArray *storedActions = [[ETRCoreDataHelper context] executeFetchRequest:fetch error:nil];
    
    ETRAction *action;
    if (storedActions && [storedActions count]) {
        if ([storedActions[0] isKindOfClass:[ETRAction class]]) {
            action = (ETRAction *)storedActions[0];
        }
    }
    
    return action;
}

+ (ETRAction *)addActionFromJSONDictionary:(NSDictionary *)jsonDictionary {
    long remoteID = [jsonDictionary longValueForKey:@"a" withFallbackValue:-102];
    if (remoteID < 10) {
        NSLog(@"WARNING: Ignoring incoming Action with Remote ID %ld." , remoteID);
        return nil;
    }
    
    // Acknowledge this Action's ID.
    [[ETRActionManager sharedManager] ackknowledgeActionID:remoteID];

    // Sender and recipient IDs may be a valid User ID, i.e. positive long,
    // or -10, the pre-defined ID for public (as recipient ID) and admin (as sender ID) messages.
    
    long senderID = [jsonDictionary longValueForKey:@"sn" withFallbackValue:-104];
    ETRUser * sender;
    if (senderID > 100L) {
        sender = [ETRCoreDataHelper userWithRemoteID:@(senderID)
                                 doLoadIfUnavailable:YES];
    } else if (senderID == ETRActionPublicUserID) {
        // TODO: Handle Server messages.
        return nil;
    } else {
        NSLog(@"WARNING: Received Action with invalid sender ID: %@", jsonDictionary);
        return nil;
    }
    
    long recipientID = [jsonDictionary longValueForKey:@"rc" withFallbackValue:-105];
    ETRUser * recipient;
    if (recipientID > 100L) {
        recipient = [ETRCoreDataHelper userWithRemoteID:@(recipientID)
                                    doLoadIfUnavailable:YES];
    } else if (recipientID != ETRActionPublicUserID) {
        NSLog(@"WARNING: Received Action with invalid recipient ID: %@", jsonDictionary);
        return nil;
    }
    
    long roomID = [jsonDictionary longValueForKey:@"r" withFallbackValue:-103];
    if (roomID < 10) {
        NSLog(@"ERROR: Received Action with invalid Room ID: %@", jsonDictionary);
        return nil;
    }
    ETRRoom * room = [ETRCoreDataHelper roomWithRemoteID:@(roomID)];
    
    // Actions that are not messages do not need to be added to the local database.
    short code = [jsonDictionary shortValueForKey:@"cd" withFallbackValue:-1];
    switch (code) {
        case ETRActionCodeKick:
            if (recipientID == [ETRLocalUserManager userID]) {
                
            }
            return nil;
            
        case ETRActionCodeBan:
            if (recipientID == [ETRLocalUserManager userID]) {
                
            }
            return nil;
            
        case ETRActionCodeUserJoin:
            [sender setInRoom:room];
            return nil;
            
        case ETRActionCodeUserQuit:
            [sender setInRoom:nil];
            return nil;
    }
    
    // Skip this Action, if an Object with this remote ID has already been stored locally
    // or if the Action has been sent by the local User.
    // Actions should not change, so they will not be updated.
    ETRAction * existingAction = [ETRCoreDataHelper actionWithRemoteID:remoteID];
    if (existingAction) {
        return nil;
    }
    
    // Incoming Actions are always unique. Just initialise a new one.
    ETRAction * receivedAction;
    receivedAction = [[ETRAction alloc] initWithEntity:[ETRCoreDataHelper actionEntity]
                        insertIntoManagedObjectContext:[ETRCoreDataHelper context]];
    
    [receivedAction setRemoteID:@(remoteID)];
    [receivedAction setSender:sender];
    [receivedAction setRecipient:recipient];
    [receivedAction setRoom:room];
    
    long timestamp = [jsonDictionary longValueForKey:@"t" withFallbackValue:1426439266];
    [receivedAction setSentDate:[NSDate dateWithTimeIntervalSince1970:timestamp]];
    
    [receivedAction setCode:@(code)];
    
    [receivedAction setMessageContent:[jsonDictionary stringForKey:@"m"]];
    
    if (recipient) {
        // If this was a private message, a recipient User object exists
        // and this Action belongs to a Conversation.
        ETRConversation * convo;
        convo = [ETRCoreDataHelper conversationWithSender:sender recipient:recipient];
        [convo updateLastMessage:receivedAction];
        [convo setHasUnreadMessage:@(YES)];
    }
    
    //    NSLog(@"Inserting Action into CoreData: %@ %@", [[receivedAction sender] remoteID], [receivedAction messageContent]);
    [ETRCoreDataHelper saveContext];
    
    return receivedAction;
}

/**
 
 */
+ (void)dispatchPublicMessage:(NSString *)messageContent {
    ETRAction * message = [ETRCoreDataHelper blankOutgoingAction];
    if (!message) {
        return;
    }
    
    [message setCode:@(ETRActionCodePublicMessage)];
    [message setMessageContent:messageContent];
    
    // Immediately store them in the Context, so that they appear in the Conversation.
    [ETRCoreDataHelper saveContext];
    
    [ETRServerAPIHelper putAction:message];
}

/**
 
 */
+ (void)dispatchMessage:(NSString *)messageContent toRecipient:(ETRUser *)recipient {
    ETRAction * message = [ETRCoreDataHelper blankOutgoingAction];
    if (!message) {
        return;
    }
    
    [message setRecipient:recipient];
    [message setCode:@(ETRActionCodePrivateMessage)];
    [message setMessageContent:messageContent];
    [message setSentDate:[NSDate date]];
    
    // Immediately store them in the Context, so that they appear in the Conversation.
    [[ETRCoreDataHelper conversationWithPartner:recipient] setLastMessage:message];
    [ETRCoreDataHelper saveContext];
    
    [ETRServerAPIHelper putAction:message];
}

/**
 
 */
+ (void)dispatchPublicImageMessage:(UIImage *)image {
    ETRAction * message = [ETRCoreDataHelper blankOutgoingAction];
    if (!message) {
        return;
    }
    [message setCode:@(ETRActionCodePublicMedia)];
    [ETRCoreDataHelper dispatchImage:image inAction:message];
}

/**
 
 */
+ (void)dispatchImageMessage:(UIImage *)image toRecipient:(ETRUser *)recipient {
    ETRAction * message = [ETRCoreDataHelper blankOutgoingAction];
    if (!message) {
        return;
    }
    [message setRecipient:recipient];
    [message setCode:@(ETRActionCodePrivateMedia)];
    [ETRCoreDataHelper dispatchImage:image inAction:message];
}

/**
 
 */
+ (void)dispatchImage:(UIImage *)image inAction:(ETRAction *)mediaAction {
    if (!image || !mediaAction) {
        return;
    }
    [mediaAction setSentDate:[NSDate date]];
    
    // Temporary image IDs are negative, random values.
    long newImageID = drand48() * LONG_MIN;
    if (newImageID > 0L) {
        newImageID *= -1L;
    }
    
#ifdef DEBUG
    NSLog(@"Dispatching image. Temporary local ID: %ld", newImageID);
#endif
    
    [mediaAction setImageID:@(newImageID)];
    
    NSData * loResData = [ETRImageEditor cropLoResImage:image
                                            writeToFile:[mediaAction imageFilePath:NO]];
    
    NSData * hiResData = [ETRImageEditor cropHiResImage:image
                                            writeToFile:[mediaAction imageFilePath:YES]];
    
    [ETRServerAPIHelper putImageWithHiResData:hiResData
                                    loResData:loResData
                                     inAction:mediaAction];
}

/**
 
 */
+ (void)queueUserUpdate {
    ETRAction * action = [ETRCoreDataHelper blankOutgoingAction];
    if (!action) {
        return;
    }
    
    [action setCode:@(ETRActionCodeUserUpdate)];
    [action setIsInQueue:@(YES)];
    
    [ETRCoreDataHelper saveContext];
}

/**
 
 */
+ (void)retrySendingQueuedActions {
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[ETRCoreDataHelper actionEntity]];
    
    NSPredicate * predicate;
    predicate = [NSPredicate predicateWithFormat:@"isInQueue == 1", @(YES)];
    [request setPredicate:predicate];
    
    NSError * error = nil;
    NSArray * actions = [[ETRCoreDataHelper context] executeFetchRequest:request
                                                                   error:&error];
    if (error) {
        NSLog(@"ERROR: %@", error);
    }
    
    for (NSManagedObject * object in actions) {
        if (![object isKindOfClass:[ETRAction class]]) {
            NSLog(@"ERROR: Queue Array contained Object that is not of kind ETRAction.");
            return;
        }
        
        ETRAction * action = (ETRAction *)object;
        
#ifdef DEBUG
        NSLog(@"Retrying to send Action %@.", action);
#endif
        
        // Some Actions trigger specific API calls.
        switch ([[action code] shortValue]) {
            case ETRActionCodeUserUpdate:
                [ETRServerAPIHelper dispatchUserUpdate];
                break;
                
            default:
                [ETRServerAPIHelper putAction:action];
                break;
        }
    }
}

+ (ETRAction *)blankOutgoingAction {
    // Outgoing messages are always unique. Just initalise a new one.
    ETRAction * message = [[ETRAction alloc] initWithEntity:[ETRCoreDataHelper actionEntity]
                            insertIntoManagedObjectContext:[ETRCoreDataHelper context]];
    
    ETRRoom * sessionRoom = [ETRSessionManager sessionRoom];
    ETRUser * localUser = [[ETRLocalUserManager sharedManager] user];
    if (!sessionRoom || !localUser) {
        NSLog(@"ERROR: Cannot build blank outgoing Action.");
        return nil;
    }
    
    [message setRoom:sessionRoom];
    [message setSender:localUser];
    [message setSentDate:[NSDate date]];
    [message setIsInQueue:@(NO)];
    
    return message;
}

+ (void)addActionToQueue:(ETRAction *)unsentAction {
    if (!unsentAction || [[unsentAction code] isEqualToNumber:@(ETRActionCodeUserQuit)]) {
        return;
    }
    
#ifndef DEBUG
    if ([[unsentAction isInQueue] boolValue]) {
        NSLog(@"Action \"%@\" is already in the queue.", unsentAction);
        return;
    }
#endif
    
    [unsentAction setIsInQueue:@(YES)];
    [ETRCoreDataHelper saveContext];
}

+ (void)removeActionFromQueue:(ETRAction *)sentAction {
    if (!sentAction) {
        return;
    }
    
    [sentAction setIsInQueue:@(NO)];
    [ETRCoreDataHelper saveContext];
}

+ (void)removeUserUpdateActionsFromQueue {
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[ETRCoreDataHelper actionEntity]];
    
    NSPredicate * predicate;
    predicate = [NSPredicate predicateWithFormat:@"%@ == %@", ETRActionCodeKey, @(ETRActionCodeUserUpdate)];
    [request setPredicate:predicate];
    [request setIncludesPropertyValues:NO];
    
    NSError * error = nil;
    NSArray * actions = [[ETRCoreDataHelper context] executeFetchRequest:request
                                                                   error:&error];
    for (NSManagedObject * action in actions) {
        [[ETRCoreDataHelper context] deleteObject:action];
    }
    
    [ETRCoreDataHelper saveContext];
}

+ (NSFetchedResultsController *)publicMessagesResultsControllerWithDelegate:(id<NSFetchedResultsControllerDelegate>)delegate
                                                       numberOfLastMessages:(NSUInteger)numberOfLastMessages {
    
    ETRRoom * sessionRoom = [[ETRSessionManager sharedManager] room];
    if (!sessionRoom || ![[ETRSessionManager sharedManager] didBeginSession]) {
        NSLog(@"ERROR: Session is not prepared.");
        return nil;
    }
    
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    NSEntityDescription * entity = [ETRCoreDataHelper actionEntity];
    [request setEntity:entity];
    
    NSString * where = [NSString stringWithFormat:@"%@.%@ == %ld AND (%@ == %i OR %@ == %i) AND %@.%@ != %@",
                        ETRActionRoomKey,
                        ETRRemoteIDKey,
                        [[sessionRoom remoteID] longValue],
                        ETRActionCodeKey,
                        ETRActionCodePublicMessage,
                        ETRActionCodeKey,
                        ETRActionCodePublicMedia,
                        ETRActionSenderKey,
                        ETRUserIsBlockedKey,
                        @(YES)];
    
    NSPredicate * predicate = [NSPredicate predicateWithFormat:where];
    [request setPredicate:predicate];
    NSArray * sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:ETRActionDateKey
                                                                ascending:YES]];
    [request setSortDescriptors:sortDescriptors];
    
    // The first request is a quick one to get the total number of records,
    // so that the fetch offset can be calculated:
    // count - numberOfLastMessages
    [request setIncludesPropertyValues:NO];

    NSError * error = nil;
    NSUInteger count = [[ETRCoreDataHelper context] countForFetchRequest:request
                                                                   error:&error];
    
    // Prepare the actual Fetch Request that is used for the Results Controller.
    [request setIncludesPropertyValues:YES];
    if (count >= numberOfLastMessages) {
        [request setFetchOffset:(count - numberOfLastMessages)];
    }
    
    NSFetchedResultsController * resultsController;
    resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                            managedObjectContext:[ETRCoreDataHelper context]
                                                              sectionNameKeyPath:nil
                                                                       cacheName:nil];
    [resultsController setDelegate:delegate];
    return resultsController;
}

+ (NSFetchedResultsController *)messagesResultsControllerForPartner:(ETRUser *)partner
                                               numberOfLastMessages:(NSUInteger)numberOfLastMessages
                                                       delegate:(id<NSFetchedResultsControllerDelegate>)delegate {
    if (!partner) {
        return nil;
    }
    
    ETRRoom * sessionRoom = [[ETRSessionManager sharedManager] room];
    if (!sessionRoom || ![[ETRSessionManager sharedManager] didBeginSession]) {
        NSLog(@"ERROR: Session is not prepared.");
        return nil;
    }
    
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[ETRCoreDataHelper actionEntity]];
    
    ETRUser * localUser = [[ETRLocalUserManager sharedManager] user];
    
    NSString * format;
    format = @"room == %@ AND ((sender == %@ AND recipient == %@) OR (recipient == %@ AND sender == %@))";
    [request setPredicate:[NSPredicate predicateWithFormat:format,
                           sessionRoom,
                           partner,
                           localUser,
                           partner,
                           localUser]];
    NSArray * sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:ETRActionDateKey
                                                                ascending:YES]];
    [request setSortDescriptors:sortDescriptors];
    
    // The first request is a quick one to get the total number of records,
    // so that the fetch offset can be calculated:
    // count - numberOfLastMessages
    [request setIncludesPropertyValues:NO];
    
    NSError * error = nil;
    NSUInteger count = [[ETRCoreDataHelper context] countForFetchRequest:request
                                                                   error:&error];
    
    // Prepare the actual Fetch Request that is used for the Results Controller.
    [request setIncludesPropertyValues:YES];
    if (count >= numberOfLastMessages) {
        [request setFetchOffset:(count - numberOfLastMessages)];
    }
    
    NSFetchedResultsController * resultsController;
    resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                            managedObjectContext:[ETRCoreDataHelper context]
                                                              sectionNameKeyPath:nil
                                                                       cacheName:nil];
    [resultsController setDelegate:delegate];
    return resultsController;
}

// TODO: Kick after connection inactivity & fix profile updates.

+ (void)cleanActions {
    NSFetchRequest * request;
    request = [[NSFetchRequest alloc] initWithEntityName:[ETRCoreDataHelper actionEntityName]];
    
    // Request all public messages and public media files
    // and anything in the queue that is not a User update.
    NSString * where = [NSString stringWithFormat:@"(%@ == %i OR %@ == %i) OR (isInQueue == 1 AND code != %i)",
                        ETRActionCodeKey,
                        ETRActionCodePublicMessage,
                        ETRActionCodeKey,
                        ETRActionCodePublicMedia,
                        ETRActionCodeUserUpdate];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:where];
    [request setPredicate:predicate];
    // Only fetch the ManagedObjectID.
    [request setIncludesPropertyValues:NO];
    
    NSError * error = nil;
    NSArray * actions = [[ETRCoreDataHelper context] executeFetchRequest:request
                                                                   error:&error];
    if (error) {
        NSLog(@"ERROR: While cleaning: %@", error);
    }
    
    for (NSManagedObject * action in actions) {
        [[ETRCoreDataHelper context] deleteObject:action];
    }

    [ETRCoreDataHelper saveContext];
}

#pragma mark -
#pragma mark Converations

+ (NSEntityDescription *)conversationEntity {
    if (!ConversationEntity) {
        ConversationEntity = [NSEntityDescription entityForName:[ETRCoreDataHelper conversationEntityName]
                                         inManagedObjectContext:[ETRCoreDataHelper context]];
    }
    return ConversationEntity;
}

+ (NSString *)conversationEntityName {
    if (!ConversationEntityName) {
        ConversationEntityName = NSStringFromClass([ETRConversation class]);
    }
    return ConversationEntityName;
}

+ (ETRConversation *)conversationWithSender:(ETRUser *)sender recipient:(ETRUser *)recipient {
    if (!sender || !recipient) {
        NSLog(@"ERROR: Insufficient User objects given to determine Conversation.");
        return nil;
    }
    
    // Determine the partner User,
    // i.e. if this message was sent from the local User or sent to them.
    if ([[ETRLocalUserManager sharedManager] isLocalUser:sender]) {
        return [ETRCoreDataHelper conversationWithPartner:recipient];
    } else {
        return [ETRCoreDataHelper conversationWithPartner:sender];
    }
}

+ (ETRConversation *)conversationWithPartner:(ETRUser *)partner {
    // Find the appropriate Conversation by using the partner User's remote ID.
    NSFetchRequest * request = [NSFetchRequest fetchRequestWithEntityName:[ETRCoreDataHelper conversationEntityName]];
    
    ETRRoom * sessionRoom = [ETRSessionManager sessionRoom];
    if (!sessionRoom) {
        NSLog(@"ERROR: Conversations require a Session Room.");
        return nil;
    }
    
    NSPredicate * predicate;
    predicate = [NSPredicate predicateWithFormat:@"partner == %@ AND inRoom == %@", partner, sessionRoom];
    [request setPredicate:predicate];
    NSArray * storedObjects = [[ETRCoreDataHelper context] executeFetchRequest:request error:nil];
    
    if (storedObjects && [storedObjects count]) {
        if ([storedObjects[0] isKindOfClass:[ETRConversation class]]) {
            return (ETRConversation *)storedObjects[0];
        }
    }
        
    // The Conversation does not exist yet.
    ETRConversation * convo = [[ETRConversation alloc] initWithEntity:[ETRCoreDataHelper conversationEntity]
                                       insertIntoManagedObjectContext:[ETRCoreDataHelper context]];
    [convo setInRoom:sessionRoom];
    [convo setPartner:partner];
    return convo;
}

+ (void)deleteConversation:(ETRConversation *)conversation {
    if (!conversation) {
        return;
    }
    
    // First delete all messages in this Conversation.
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[ETRCoreDataHelper actionEntity]];
    
    NSPredicate * predicate;
    predicate = [NSPredicate predicateWithFormat:@"(code == %i OR code == %i) AND (sender == %@ OR recipient == %@)",
                 ETRActionCodePrivateMessage,
                 ETRActionCodePrivateMedia,
                 [conversation partner],
                 [conversation partner]];
    [request setPredicate:predicate];
    [request setIncludesPropertyValues:NO];
    
    NSError * error = nil;
    NSArray * actions = [[ETRCoreDataHelper context] executeFetchRequest:request
                                                                   error:&error];
    for (NSManagedObject * action in actions) {
        [[ETRCoreDataHelper context] deleteObject:action];
    }
    
    
    [ETRCoreDataHelper deleteObject:conversation];
    [ETRCoreDataHelper saveContext];
}


+ (NSFetchedResultsController *)conversationResulsControllerWithDelegate:(id<NSFetchedResultsControllerDelegate>)delegate {
    ETRRoom *sessionRoom = [[ETRSessionManager sharedManager] room];
    if (!sessionRoom || ![[ETRSessionManager sharedManager] didBeginSession]) {
        NSLog(@"ERROR: Session is not prepared.");
        return nil;
    }
    
    NSFetchRequest *fetchRequest;
    fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[ETRCoreDataHelper conversationEntityName]];
    
    NSString *where = [NSString stringWithFormat:@"%@.%@ == %ld",
                       ETRInRoomKey,
                       ETRRemoteIDKey,
                       [[sessionRoom remoteID] longValue]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:where];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"lastMessage.sentDate" ascending:YES]]];
    
    NSFetchedResultsController *resultsController;
    resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                            managedObjectContext:[ETRCoreDataHelper context]
                                                              sectionNameKeyPath:nil
                                                                       cacheName:nil];
    // Configure Fetched Results Controller
    [resultsController setDelegate:delegate];
    return resultsController;
}

#pragma mark -
#pragma mark Rooms

+ (void)insertRoomFromDictionary:(NSDictionary *)JSONDict {
    
    // Get the remote DB ID from the JSON data.
    long remoteID = (long) [[JSONDict objectForKey:@"r"] longLongValue];
    
    // Check the context CoreData, if an object with this remote ID already exists.
    ETRRoom *room = [ETRCoreDataHelper roomWithRemoteID:@(remoteID)];
    
    [room setImageID:@((long) [[JSONDict objectForKey:@"i"] longLongValue])];
    NSString *radius = (NSString *)[JSONDict objectForKey:@"rd"];
    [room setRadius:@((short) [radius integerValue])];
    NSString *userCount = (NSString *)[JSONDict objectForKey:@"ucn"];
    [room setQueryUserCount:@((short) [userCount integerValue])];
    
    [room setTitle:(NSString *)[JSONDict objectForKey:@"tt"]];
    [room setSummary:(NSString *)[JSONDict objectForKey:@"ds"]];
    [room setPassword:(NSString *)[JSONDict objectForKey:@"pw"]];

    
    NSInteger startTimestamp = [(NSString *)[JSONDict objectForKey:@"st"] integerValue];
    if (startTimestamp > 1000000000) {
        [room setStartTime:[NSDate dateWithTimeIntervalSince1970:startTimestamp]];
    }
    
    NSInteger endTimestamp = [(NSString *)[JSONDict objectForKey:@"et"] integerValue];
    if (endTimestamp > 1000000000) {
        [room setEndDate:[NSDate dateWithTimeIntervalSince1970:startTimestamp]];
    }
    
    // We query the database with km values and only use metre integer precision.
    NSString * distance = (NSString *)[JSONDict objectForKey:@"dst"];
    [room setQueryDistance:@([distance integerValue] * 1000)];
    NSString * latitude = (NSString *)[JSONDict objectForKey:@"lat"];
    [room setLatitude:@([latitude floatValue])];
    NSString * longitude = (NSString *)[JSONDict objectForKey:@"lng"];
    [room setLongitude:@([longitude floatValue])];
    
    [room setAddress:[JSONDict stringForKey:@"ad"]];
    
    NSLog(@"Inserting Room: %@", [room description]);
    [ETRCoreDataHelper saveContext];
}

+ (ETRRoom *)roomWithRemoteID:(NSNumber *)remoteID {
    //    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:[ETRCoreDataHelper roomEntityName]];
    
    NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
    [fetch setEntity:[ETRCoreDataHelper roomEntity]];
    NSString * where = [NSString stringWithFormat:@"%@ == %@", ETRRemoteIDKey, remoteID];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:where];
    [fetch setPredicate:predicate];
    NSArray *existingRooms = [[ETRCoreDataHelper context] executeFetchRequest:fetch error:nil];
    
    if (existingRooms && [existingRooms count]) {
        if ([existingRooms[0] isKindOfClass:[ETRRoom class]]) {
            return (ETRRoom *)existingRooms[0];
        }
    }
    
    ETRRoom * room = [[ETRRoom alloc] initWithEntity:[ETRCoreDataHelper roomEntity]
                      insertIntoManagedObjectContext:[ETRCoreDataHelper context]];
    [room setRemoteID:remoteID];
    return room;
}

+ (NSFetchedResultsController *)roomListResultsController {
    NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[ETRCoreDataHelper roomEntityName]];
    
    // Add Sort Descriptors
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:ETRRoomDistanceKey ascending:YES]]];
    
    // Initialize Fetched Results Controller
    NSFetchedResultsController * resultsController;
    resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                   managedObjectContext:[ETRCoreDataHelper context]
                                                                     sectionNameKeyPath:nil
                                                                              cacheName:nil];
    
    // Configure Fetched Results Controller
//    [resultsController setDelegate:delegate];
    return resultsController;
}

#pragma mark -
#pragma mark User Objects

+ (NSFetchedResultsController *)userListResultsControllerWithDelegate:(id<NSFetchedResultsControllerDelegate>)delegate {
    ETRRoom * sessionRoom = [[ETRSessionManager sharedManager] room];
    if (!sessionRoom || ![[ETRSessionManager sharedManager] didBeginSession]) {
        NSLog(@"ERROR: Session is not prepared.");
        return nil;
    }
    
    NSFetchRequest * request;
    request = [[NSFetchRequest alloc] initWithEntityName:[ETRCoreDataHelper userEntityName]];
    
//    NSString *where = [NSString stringWithFormat:@"%@.%@ == %ld AND %@ != 1",
//                       ETRInRoomKey,
//                       ETRRemoteIDKey,
//                       [[sessionRoom remoteID] longValue],
//                       ETRUserIsBlockedKey];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inRoom == %@ AND isBlocked != 1", sessionRoom];
    [request setPredicate:predicate];
    [request setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:ETRUserNameKey ascending:YES]]];
    
    NSFetchedResultsController * resultsController;
    resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                            managedObjectContext:[ETRCoreDataHelper context]
                                                              sectionNameKeyPath:nil
                                                                       cacheName:nil];
    // Configure Fetched Results Controller
    [resultsController setDelegate:delegate];
    return resultsController;
}

+ (NSFetchedResultsController *)blockedUserListControllerWithDelegate:(id<NSFetchedResultsControllerDelegate>)delegate {
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[ETRCoreDataHelper userEntity]];
    
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"isBlocked == 1"];
    [request setPredicate:predicate];
    [request setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:ETRUserNameKey ascending:YES]]];
    
    NSFetchedResultsController * resultsController;
    resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                            managedObjectContext:[ETRCoreDataHelper context]
                                                              sectionNameKeyPath:nil
                                                                       cacheName:nil];
    
    [resultsController setDelegate:delegate];
    return resultsController;
}

+ (ETRUser *)insertUserFromDictionary:(NSDictionary *)jsonDictionary {
    // Get the remote DB ID from the JSON data.
    long remoteID = [jsonDictionary longValueForKey:@"u" withFallbackValue:-55];
    
    if (remoteID < 10) {
        NSLog(@"ERROR: Could not insert User because remote ID is invalid: %ld", remoteID);
        return nil;
    }
    
    // Get the existing Object or an empty one to fill.
    ETRUser * user = [ETRCoreDataHelper userWithRemoteID:@(remoteID) doLoadIfUnavailable:NO];
    
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
    [ETRCoreDataHelper saveContext];
    return user;
}

+ (ETRUser *)copyUser:(ETRUser *)user {
    ETRUser *copiedUser = [[ETRUser alloc] initWithEntity:[ETRCoreDataHelper userEntity]
                           insertIntoManagedObjectContext:[ETRCoreDataHelper context]];
    
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

+ (ETRUser *)userWithRemoteID:(NSNumber *)remoteID
          doLoadIfUnavailable:(BOOL)doLoadIfUnavailable{
    
    if ([remoteID longValue] < 100L) {
        return nil;
    }
    
    // Check the context CoreData, if an object with this remote ID exists.
    NSFetchRequest * request;
    request = [NSFetchRequest fetchRequestWithEntityName:[ETRCoreDataHelper userEntityName]];
//    NSString *where = [NSString stringWithFormat:@"%@ == %ld", ETRRemoteIDKey, remoteID];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"remoteID = %@", remoteID];
    [request setPredicate:predicate];
    NSArray *existingUsers = [[ETRCoreDataHelper context] executeFetchRequest:request error:nil];
    
    if (existingUsers && [existingUsers count]) {
        if ([existingUsers[0] isKindOfClass:[ETRUser class]]) {
            return (ETRUser *)existingUsers[0];
        }
    }
    
    if (doLoadIfUnavailable) {
        [ETRServerAPIHelper getUserWithID:remoteID];
    }
    
    ETRUser *newUser = [[ETRUser alloc] initWithEntity:[ETRCoreDataHelper userEntity]
                        insertIntoManagedObjectContext:[ETRCoreDataHelper context]];
    [newUser setRemoteID:remoteID];
    [newUser setName:NSLocalizedString(@"Unknown_User", @"Name placeholder")];
    [newUser setStatus:@"..."];
    
    return newUser;
}

@end

#pragma mark -
#pragma mark JSON Dictionary Category

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
    NSString * value = [self stringForKey:key];
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
