/*
 ETRManager.h
 Realay
 
 Created by Michel S on 02.03.14.
 Copyright (c) 2014 Michel Sievers. All rights reserved.
 
 Singleton:
 Manages all relations the user has to the room, as well as some global settings.
 Decides if the user may (and does) participate in a room
 through the distance to the room and actions like join, leave or kicks.
*/

#import <Foundation/Foundation.h>

#import "ETRAction.h"
#import "ETRLocalUserManager.h"
#import "ETRLocationHelper.h"
#import "ETRRoom.h"

# pragma mark - Delegate Protocols
@protocol ETRChatDelegate <NSObject>

- (void)chatDidUpdateWithKey:(NSString *)chatKey;

@end

@protocol ETRRelayedLocationDelegate <NSObject>

- (void)sessionDidUpdateLocationManager:(ETRLocationHelper *)manager;

@end

@protocol ETRUserListDelegate <NSObject>

- (void)didUpdateUserChatList;

@end

# pragma mark - Interface
@interface ETRSession : NSObject <CLLocationManagerDelegate>

@property (strong, nonatomic, readonly) User * publicDummyUser;

/*
 View controller that needs constant message updates:
 */
@property (weak, nonatomic) id<ETRChatDelegate> chatDelegate;

/*
 View controller that needs constant location updates:
  */
@property (weak, nonatomic) id<ETRRelayedLocationDelegate> locationDelegate;

/*
 View controller that needs constant user list updates:
  */
@property (weak, nonatomic) id<ETRUserListDelegate> userListDelegate;

/*
 Chat that does not need notifications.
 To be modified by view controllers on appear/disappear.
 */
@property (nonatomic) NSInteger activeChatID;

/*
 Stores if the user has joined a room.
  */
@property (nonatomic, readonly) BOOL didBeginSession;

/*
 Stores if the user is inside the region of a room.
  */
@property (nonatomic, readonly) BOOL isInRegion;

/*
 Return to this view when clicking the map button after joining.
  */
@property (nonatomic) NSInteger mapControllerIndex;

/*
 Font that is to be used for the sender label of a message:
  */
@property (strong, nonatomic, readonly) UIFont *msgSenderFont;

/*
 Font that is to be used for the message itself:
  */
@property (strong, nonatomic, readonly) UIFont *msgTextFont;

/*
 Session is able to push/pop view controller.
  */
@property (strong, nonatomic) UINavigationController *navigationController;

/*
 Number of failed location updates:
  */
@property (nonatomic, readonly) NSInteger locationUpdateFails;

/*
 Room object of this session:
  */
@property (strong, nonatomic, readonly) ETRRoom *room;

/*
 Return to the view controller at this index when leaving.
  */
@property (nonatomic) NSInteger roomListControllerIndex;

/*
 Return to the user/chat list controller when blocking someone.
 */
@property (nonatomic) NSInteger userListControllerIndex;

/*
 All user objects in this session:
  */
@property (strong, nonatomic, readonly) NSMutableArray *users;

/*
 Keys of all chats sorted by last message date:
  */
@property (strong, nonatomic, readonly) NSMutableArray *sortedChatKeys;

/*
 Keys of all users sorted by name:
  */
@property (strong, nonatomic, readonly) NSMutableArray *sortedUserKeys;

# pragma mark - Methods

/* 
 The shared singleton instance:
  */
+ (ETRSession *)sharedManager;

/*
 To be called by view controllers receiving memory warnings.
 */
- (void)didReceiveMemoryWarning;

/*
 Become a member of a room and start a new session.
 */
- (void)beginSession;

/*
 Remove user from the room, reset attributes and return to the room list.
 */
- (void)endSession;

/*
 Prepare the session manager so it can join a room later.
 */
- (void)prepareSessionInRoom:(ETRRoom *)room
        navigationController:(UINavigationController *)navigationController;

/*
 Get all new actions from the database.
 */
- (void)tick;

/*
 Get a complete list of users for this session.
 */
- (void)queryUserList;

/*
 Read the user settings.
 */
- (void)refreshGUIAttributes;

/*
 Used when app moves to the background.
 */
- (void)switchToBackgroundSession;

/*
 Used when the app moves back to the foreground.
 */
- (void)switchToForegroundSession;

/*
 Reset the location manager, so the room list can be queried.
 */
- (void)resetLocationManager;

@end
