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
#import "ETRBouncer.h"
#import "ETRConversation.h"
#import "ETRImageEditor.h"
#import "ETRLocalUserManager.h"
#import "ETRLocationManager.h"
#import "ETRRoom.h"
#import "ETRServerAPIHelper.h"
#import "ETRSessionManager.h"
#import "ETRUser.h"


long const ETRActionPublicUserID = -10;

static NSEntityDescription * ActionEntity;

static NSEntityDescription * ConversationEntity;

static NSEntityDescription * RoomEntity;

static NSEntityDescription * UserEntity;


@implementation ETRCoreDataHelper

#pragma mark -
#pragma mark Accessories

+ (NSManagedObjectContext *)context {
    ETRAppDelegate * app = (ETRAppDelegate *) [[UIApplication sharedApplication] delegate];
    return [app managedObjectContext];
}

+ (NSEntityDescription *)roomEntity {
    if (!RoomEntity) {
        NSString * roomEntityName = NSStringFromClass([ETRRoom class]);
        RoomEntity = [NSEntityDescription entityForName:roomEntityName
                                 inManagedObjectContext:[ETRCoreDataHelper context]];
    }
    return RoomEntity;
}

+ (NSEntityDescription *)userEntity {
    if (!UserEntity) {
        NSString * userEntityName = NSStringFromClass([ETRUser class]);
        UserEntity = [NSEntityDescription entityForName:userEntityName
                                 inManagedObjectContext:[ETRCoreDataHelper context]];
    }
    return UserEntity;
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
        NSString * actionEntityName = NSStringFromClass([ETRAction class]);
        ActionEntity = [NSEntityDescription entityForName:actionEntityName
                                   inManagedObjectContext:[ETRCoreDataHelper context]];
    }
    return ActionEntity;
}

+ (ETRAction *)actionWithRemoteID:(NSNumber *)remoteID {
    NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
    [fetch setEntity:[ETRCoreDataHelper actionEntity]];
    [fetch setPredicate:[NSPredicate predicateWithFormat:@"remoteID == %@", remoteID]];
    NSArray *storedActions = [[ETRCoreDataHelper context] executeFetchRequest:fetch error:nil];
    
    ETRAction *action;
    if (storedActions && [storedActions count]) {
        if ([storedActions[0] isKindOfClass:[ETRAction class]]) {
            action = (ETRAction *)storedActions[0];
        }
    }
    
    return action;
}


/**
 Takes a JSON server response in a Dictionary,
 translates it into an Action Object
 and handles the intent of the Action
 or adds Messages to the CoreData.
 
 Does NOT save the Context.
 */
+ (ETRAction *)addActionFromJSONDictionary:(NSDictionary *)jsonDictionary
                            isInitialQuery:(BOOL)isInitial {
    
    long remoteID = [jsonDictionary longValueForKey:@"a" fallbackValue:-102];
    if (remoteID < 10) {
#ifdef DEBUG
        NSLog(@"WARNING: Ignoring incoming Action with Remote ID %ld." , remoteID);
#endif
        return nil;
    }
    
    // Acknowledge this Action's ID.
    [[ETRActionManager sharedManager] ackknowledgeActionID:remoteID];

    // Sender and recipient IDs may be a valid User ID, i.e. positive long,
    // or -10, the pre-defined ID for public (as recipient ID) and admin (as sender ID) messages.
    
    long senderID = [jsonDictionary longValueForKey:@"sn" fallbackValue:-104];
    ETRUser * sender;
    if (senderID > 100L) {
        sender = [ETRCoreDataHelper userWithRemoteID:@(senderID)
                                 doLoadIfUnavailable:YES];
    } else if (senderID == ETRActionPublicUserID) {
        // TODO: Handle Server messages.
        return nil;
    } else {
#ifdef DEBUG
        NSLog(@"WARNING: Received Action with invalid sender ID: %@", jsonDictionary);
#endif
        return nil;
    }
    
    long recipientID = [jsonDictionary longValueForKey:@"rc" fallbackValue:-105];
    ETRUser * recipient;
    if (recipientID > 100L) {
        recipient = [ETRCoreDataHelper userWithRemoteID:@(recipientID)
                                    doLoadIfUnavailable:YES];
    } else if (recipientID != ETRActionPublicUserID) {
#ifdef DEBUG
        NSLog(@"WARNING: Received Action with invalid recipient ID: %@", jsonDictionary);
#endif
        return nil;
    }
    
    long roomID = [jsonDictionary longValueForKey:@"r" fallbackValue:-103];
    if (roomID < 10) {
#ifdef DEBUG
        NSLog(@"ERROR: Received Action with invalid Room ID: %@", jsonDictionary);
#endif
        return nil;
    }
    ETRRoom * room = [ETRCoreDataHelper roomWithRemoteID:@(roomID)];
    
    // Actions that are not messages do not need to be added to the local database.
    short code = [jsonDictionary shortValueForKey:@"cd" fallbackValue:-1];
    switch (code) {
        case ETRActionCodeKick:
            if (!isInitial && recipientID == [ETRLocalUserManager userID]) {
                [[ETRBouncer sharedManager] kickForReason:ETRKickReasonKick calledBy:@"kickAction"];
            }
            return nil;
            
        case ETRActionCodeBan:
            if (!isInitial && recipientID == [ETRLocalUserManager userID]) {
                [[ETRBouncer sharedManager] kickForReason:ETRKickReasonKick calledBy:@"banAction"];
                [ETRCoreDataHelper deleteObject:room];
            }
            return nil;
            
        case ETRActionCodeUserJoin:
            if (!isInitial && senderID != [ETRLocalUserManager userID]) {
                [sender setInRoom:room];
            }
            return nil;
            
        case ETRActionCodeUserUpdate:
            if (!isInitial && senderID != [ETRLocalUserManager userID]) {
                [ETRServerAPIHelper getUserWithID:[sender remoteID]];
                [sender setInRoom:room];
            }
            return nil;
            
        case ETRActionCodeUserQuit:
            if (!isInitial && senderID != [ETRLocalUserManager userID]) {
                [sender setInRoom:nil];
            }
            return nil;
    }
    
    // Skip this Action, if an Object with this remote ID has already been stored locally
    // or if the Action has been sent by the local User.
    // Actions should not change, so they will not be updated.
    ETRAction * existingAction = [ETRCoreDataHelper actionWithRemoteID:@(remoteID)];
    if (existingAction) {
#ifdef DEBUG
        NSLog(@"Action already exists: %@", existingAction);
#endif
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
    
    long timestamp = [jsonDictionary longValueForKey:@"t" fallbackValue:1426439266];
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
        
#ifdef DEBUG
        NSLog(@"Action has recipient: %@", receivedAction);
#endif
    }
    
    if (!isInitial) {
        // If this Action arrives mid-session, the User has to be in the Room.
        [sender setInRoom:room];
    }
    
    return receivedAction;
}

/**
 Saves Managed Object Context.
 */
+ (void)dispatchPublicMessage:(NSString *)messageContent {
    ETRAction * message = [ETRCoreDataHelper blankOutgoingAction];
    if (!message) {
        return;
    }
    
    // Prepare the Message Action for sending.
    [message setCode:@(ETRActionCodePublicMessage)];
    [message setMessageContent:messageContent];
    
    // Immediately store them in the Context, so that they appear in the Conversation.
    [ETRCoreDataHelper saveContext];
    
    [ETRServerAPIHelper putAction:message];
}

/**
 Saves Managed Object Context.
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
    
    NSData * loResData = [ETRImageEditor scalePreviewImage:image
                                               writeToFile:[mediaAction imageFilePath:NO]];
    
    NSData * hiResData = [ETRImageEditor scaleLimitMessageImage:image
                                                    writeToFile:[mediaAction imageFilePath:YES]];
    
    [ETRServerAPIHelper putImageWithHiResData:hiResData
                                    loResData:loResData
                                     inAction:mediaAction];
}

/**
 Saves Managed Object Context.
 */
+ (void)queueUserUpdate {
    ETRAction * action = [ETRCoreDataHelper blankOutgoingAction];
    if (!action) {
        return;
    }
    
    [action setCode:@(ETRActionCodeUserUpdate)];
    [action setIsInQueue:@(YES)];
    
    [ETRCoreDataHelper saveContext];
#ifdef DEBUG
    NSLog(@"Saved queued User Update in Context.");
#endif
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
        NSLog(@"ERROR: retrySendingQueuedActions: %@", error);
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
    ETRRoom * sessionRoom = [ETRSessionManager sessionRoom];
    ETRUser * localUser = [[ETRLocalUserManager sharedManager] user];
    if (!sessionRoom || !localUser) {
        NSLog(@"ERROR: Cannot build blank outgoing Action.");
        return nil;
    }
    
    // Outgoing messages are always unique. Just initalise a new one.
    ETRAction * message = [[ETRAction alloc] initWithEntity:[ETRCoreDataHelper actionEntity]
                             insertIntoManagedObjectContext:[ETRCoreDataHelper context]];
    
    [message setRoom:sessionRoom];
    [message setSender:localUser];
    [message setSentDate:[NSDate date]];
    [message setIsInQueue:@(NO)];
    
    return message;
}

/**
 Saves Managed Object Context.
 */
+ (void)addActionToQueue:(ETRAction *)unsentAction {
    if (!unsentAction || [[unsentAction code] isEqualToNumber:@(ETRActionCodeUserQuit)]) {
        return;
    }
    
    if ([[unsentAction isInQueue] boolValue]) {
#ifdef DEBUG
        NSLog(@"Action \"%@\" is already in the queue.", unsentAction);
#endif
    } else {
        [unsentAction setIsInQueue:@(YES)];
        [ETRCoreDataHelper saveContext];
    }
}

/**
 Saves Managed Object Context.
 */
+ (void)removeActionFromQueue:(ETRAction *)sentAction {
    if (!sentAction) {
        return;
    }
    
    [sentAction setIsInQueue:@(NO)];
    [ETRCoreDataHelper saveContext];
}

/**
 Does NOT save Managed Object Context.
 */
+ (void)removeUserUpdateActionsFromQueue {
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[ETRCoreDataHelper actionEntity]];
    
    [request setPredicate:[NSPredicate predicateWithFormat:@"code == %i", ETRActionCodeUserUpdate]];
    [request setIncludesPropertyValues:NO];
    
    NSError * error = nil;
    NSArray * actions = [[ETRCoreDataHelper context] executeFetchRequest:request
                                                                   error:&error];
    for (NSManagedObject * action in actions) {
        [[ETRCoreDataHelper context] deleteObject:action];
    }
}

+ (NSFetchedResultsController *)publicMessagesResultsControllerWithDelegate:(id<NSFetchedResultsControllerDelegate>)delegate
                                                       numberOfLastMessages:(NSUInteger)numberOfLastMessages {
    
    ETRRoom * sessionRoom = [[ETRSessionManager sharedManager] room];
    if (!sessionRoom || ![[ETRSessionManager sharedManager] didStartSession]) {
        NSLog(@"ERROR: Session is not prepared.");
        return nil;
    }
    
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    NSEntityDescription * entity = [ETRCoreDataHelper actionEntity];
    [request setEntity:entity];
    
    NSPredicate * predicate;
    predicate = [NSPredicate predicateWithFormat:@"room == %@ AND (code == %i OR code == %i) AND sender.isBlocked != 1",
                 sessionRoom,
                 ETRActionCodePublicMessage,
                 ETRActionCodePublicMedia];
    [request setPredicate:predicate];
    NSArray * sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sentDate"
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
    if (!sessionRoom || ![[ETRSessionManager sharedManager] didStartSession]) {
        NSLog(@"ERROR: Session is not prepared.");
        return nil;
    }
    
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[ETRCoreDataHelper actionEntity]];
    
    ETRUser * localUser = [[ETRLocalUserManager sharedManager] user];
    
    NSPredicate * predicate;
    predicate = [NSPredicate predicateWithFormat:@"room == %@ AND ((sender == %@ AND recipient == %@) OR (recipient == %@ AND sender == %@))",
                 sessionRoom,
                 partner,
                 localUser,
                 partner,
                 localUser];
    [request setPredicate:predicate];
    NSArray * sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sentDate"
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

// TODO: Fix profile updates.

+ (void)cleanActions {
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[ETRCoreDataHelper actionEntity]];
    
    // Request all public messages and public media files
    // and anything in the queue that is not a User update.
    NSPredicate * predicate;
    predicate = [NSPredicate predicateWithFormat:@"(code == %i OR code == %i) OR (isInQueue == 1 AND code != %i)",
                 ETRActionCodePublicMessage,
                 ETRActionCodePublicMedia,
                 ETRActionCodeUserUpdate];
    [request setPredicate:predicate];
    // Only fetch the ManagedObjectID.
    [request setIncludesPropertyValues:NO];
    
    NSError * error = nil;
    NSArray * actions = [[ETRCoreDataHelper context] executeFetchRequest:request
                                                                   error:&error];
    if (error) {
        NSLog(@"ERROR: cleanActions: %@", error);
    }
    
    for (NSManagedObject * action in actions) {
        [[ETRCoreDataHelper context] deleteObject:action];
    }

//    [ETRCoreDataHelper saveContext];
}

#pragma mark -
#pragma mark Converations

+ (NSEntityDescription *)conversationEntity {
    if (!ConversationEntity) {
        NSString * conversationEntityName = NSStringFromClass([ETRConversation class]);
        ConversationEntity = [NSEntityDescription entityForName:conversationEntityName
                                         inManagedObjectContext:[ETRCoreDataHelper context]];
    }
    return ConversationEntity;
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
    ETRRoom * sessionRoom = [ETRSessionManager sessionRoom];
    if (!sessionRoom) {
        NSLog(@"ERROR: Conversations require a Session Room.");
        return nil;
    }
    
    // Find the appropriate Conversation by using the partner User's remote ID.
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[ETRCoreDataHelper conversationEntity]];
    
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

/**
 Saves Managed Object Context.
 */
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
    if (!sessionRoom || ![[ETRSessionManager sharedManager] didStartSession]) {
        NSLog(@"ERROR: Session is not prepared.");
        return nil;
    }
    
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[ETRCoreDataHelper conversationEntity]];
    
    [request setPredicate:[NSPredicate predicateWithFormat:@"inRoom == %@", sessionRoom]];
    [request setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"lastMessage.sentDate" ascending:NO]]];
    
    NSFetchedResultsController *resultsController;
    resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                            managedObjectContext:[ETRCoreDataHelper context]
                                                              sectionNameKeyPath:nil
                                                                       cacheName:nil];
    // Configure Fetched Results Controller
    [resultsController setDelegate:delegate];
    return resultsController;
}

#pragma mark -
#pragma mark Rooms

+ (NSArray *)rooms {
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[ETRCoreDataHelper roomEntity]];
    
    NSError * error;
    NSArray * rooms = [[ETRCoreDataHelper context] executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"ERROR: rooms: %@",error);
        return nil;
    } else {
        return rooms;
    }
}

/**
 Does NOT save the Managed Object Context.
 */
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

    
    NSInteger unixStartDate = [(NSString *)[JSONDict objectForKey:@"st"] integerValue];
    if (unixStartDate > 1000) {
        [room setStartDate:[NSDate dateWithTimeIntervalSince1970:unixStartDate]];
    } else {
        [room setStartDate:nil];
    }
    
    NSInteger unixEndDate = [(NSString *)[JSONDict objectForKey:@"et"] integerValue];
    if (unixEndDate > 1000) {
        [room setEndDate:[NSDate dateWithTimeIntervalSince1970:unixEndDate]];
    } else {
        [room setEndDate:nil];
    }
    
    // We query the database with km values and only use metre integer precision.
//    double kmDistance = [JSONDict doubleValueForKey:@"dst" fallbackValue:7777.7];
    [room setLatitude:@([JSONDict doubleValueForKey:@"lat" fallbackValue:0.0])];
    [room setLongitude:@([JSONDict doubleValueForKey:@"lng" fallbackValue:0.0])];
    
    [room setDistance:@([[ETRLocationManager sharedManager] distanceToRoom:room])];
    
    [room setAddress:[JSONDict stringForKey:@"ad"]];
    
#ifdef DEBUG
    NSLog(@"Inserting Room: %@", [room description]);
#endif
}

+ (ETRRoom *)roomWithRemoteID:(NSNumber *)remoteID {
    //    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:[ETRCoreDataHelper roomEntityName]];
    
    NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
    [fetch setEntity:[ETRCoreDataHelper roomEntity]];
    [fetch setPredicate:[NSPredicate predicateWithFormat:@"remoteID == %@", remoteID]];
    NSError * error;
    NSArray *existingRooms = [[ETRCoreDataHelper context] executeFetchRequest:fetch
                                                                        error:&error];
    
    if (error) {
        NSLog(@"ERROR: roomWithRemoteID: : %@", error);
    }
    
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
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[ETRCoreDataHelper roomEntity]];
    
    
    NSPredicate * predicate;
    predicate = [NSPredicate predicateWithFormat:@"(endDate > %@ || endDate == nil) && distance < 20000", [NSDate date]];
    [request setPredicate:predicate];
    
    // Sort by distance.
    NSSortDescriptor * sortDescriptor;
    sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"distance" ascending:YES];
    [request setSortDescriptors:@[sortDescriptor]];
    
    
    // Initialize Fetched Results Controller
    NSFetchedResultsController * resultsController;
    resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                   managedObjectContext:[ETRCoreDataHelper context]
                                                                     sectionNameKeyPath:nil
                                                                              cacheName:nil];
    
    // Configure Fetched Results Controller
//    [resultsController setDelegate:delegate];
    return resultsController;
}

#pragma mark -
#pragma mark Users

+ (NSArray *)blockedUsers {
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[ETRCoreDataHelper userEntity]];
    
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"isBlocked == 1"];
    [request setPredicate:predicate];
    
    NSError * error;
    NSArray * blockedUsers = [[ETRCoreDataHelper context] executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"ERROR: blockedUsers: %@", error);
        return nil;
    } else {
        return blockedUsers;
    }
}

+ (int)numberOfUsersInSessionRoom {
    ETRRoom * sessionRoom = [[ETRSessionManager sharedManager] room];
    if (!sessionRoom) {
        return 1;
    }
    
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[ETRCoreDataHelper userEntity]];
    [request setPredicate:[NSPredicate predicateWithFormat:@"inRoom == %@", sessionRoom]];
    [request setIncludesPropertyValues:NO];
    
    NSError * error = nil;
    int count = (int) [[ETRCoreDataHelper context] countForFetchRequest:request
                                                                   error:&error];
    
    if (error) {
        NSLog(@"ERROR: numberOfUsersInSessionRoom: %@", [error description]);
        return 11;
    } else {
        return count + 1;
    }
}

+ (NSFetchedResultsController *)userListResultsControllerWithDelegate:(id<NSFetchedResultsControllerDelegate>)delegate {
    ETRRoom * sessionRoom = [[ETRSessionManager sharedManager] room];
    if (!sessionRoom || ![[ETRSessionManager sharedManager] didStartSession]) {
        NSLog(@"ERROR: Session is not prepared.");
        return nil;
    }
    
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[ETRCoreDataHelper userEntity]];
    
    NSPredicate * predicate;
    predicate = [NSPredicate predicateWithFormat:@"inRoom == %@ AND isBlocked != 1", sessionRoom];
    [request setPredicate:predicate];
    NSSortDescriptor * sortDescriptor;
    sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    [request setSortDescriptors:@[sortDescriptor]];
    
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
    NSSortDescriptor * sortDescriptor;
    sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    [request setSortDescriptors:@[sortDescriptor]];
    
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
    long remoteID = [jsonDictionary longValueForKey:@"u" fallbackValue:-55];
    
    if (remoteID < 10) {
#ifdef DEBUG
        NSLog(@"ERROR: Could not insert User because remote ID is invalid: %ld", remoteID);
#endif
        return nil;
    }
    
    // Get the existing Object or an empty one to fill.
    ETRUser * user = [ETRCoreDataHelper userWithRemoteID:@(remoteID) doLoadIfUnavailable:NO];
    if (!user) {
#ifdef DEBUG
        NSLog(@"ERROR: Could not initialize User. %ld", remoteID);
#endif
        return nil;
    }
    
    [user setImageID:@([jsonDictionary longValueForKey:@"i" fallbackValue:-5L])];
    [user setName:[jsonDictionary stringForKey:@"n"]];
    [user setStatus:[jsonDictionary stringForKey:@"s"]];
    [user setMail:[jsonDictionary stringForKey:@"em"]];
    [user setPhone:[jsonDictionary stringForKey:@"ph"]];
    [user setWebsite:[jsonDictionary stringForKey:@"ws"]];
    [user setFacebook:[jsonDictionary stringForKey:@"fb"]];
    [user setInstagram:[jsonDictionary stringForKey:@"ig"]];
    [user setTwitter:[jsonDictionary stringForKey:@"tw"]];
    
//    NSLog(@"Inserting User: %@", [user description]);
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
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[ETRCoreDataHelper userEntity]];
    [request setPredicate:[NSPredicate predicateWithFormat:@"remoteID = %@", remoteID]];
    NSArray * existingUsers = [[ETRCoreDataHelper context] executeFetchRequest:request error:nil];
    
    if (existingUsers && [existingUsers count]) {
        if ([existingUsers[0] isKindOfClass:[ETRUser class]]) {
            return (ETRUser *)existingUsers[0];
        }
    }
    
    if (doLoadIfUnavailable) {
        [ETRServerAPIHelper getUserWithID:remoteID];
    }
    
    ETRUser * newUser = [[ETRUser alloc] initWithEntity:[ETRCoreDataHelper userEntity]
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
//        NSLog(@"ERROR: %@ not found in JSON Dictionary.", key);
        return nil;
    }
}

- (double)doubleValueForKey:(id)key fallbackValue:(double)fallbackValue {
    NSString * value = [self stringForKey:key];
    if (value) {
        return [value doubleValue];
    } else {
        return fallbackValue;
    }
}

- (int)intValueForKey:(id)key fallbackValue:(int)fallbackValue {
    NSString * value = [self stringForKey:key];
    if (value) {
        return (int) [value integerValue];
    } else {
        return fallbackValue;
    }
}

- (long)longValueForKey:(id)key fallbackValue:(long)fallbackValue {
    NSString * value = [self stringForKey:key];
    if (value) {
        return (long) [value longLongValue];
    } else {
        return fallbackValue;
    }
}

- (short)shortValueForKey:(id)key fallbackValue:(short)fallbackValue {
    NSString *value = [self stringForKey:key];
    if (value) {
        return [value integerValue];
    } else {
        return fallbackValue;
    }
}

@end
