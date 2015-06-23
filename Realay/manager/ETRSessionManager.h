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

#import <UIKit/UIKit.h>

@class ETRAction;
@class ETRRoom;

@interface ETRSessionManager : NSObject

/*
 Chat that does not need notifications.
 To be modified by view controllers on appear/disappear.
 */
@property (nonatomic) NSInteger activeChatID;

/*
 Stores if the user has joined a room.
  */
@property (nonatomic, readonly) BOOL didStartSession;

/*
 Session is able to push/pop view controller.
  */
@property (strong, nonatomic) UINavigationController * navigationController;

/*
 Room object of this session:
  */
@property (strong, nonatomic, readonly) ETRRoom *room;

/*
 Return to the user/chat list controller when blocking someone.
 */
@property (nonatomic) NSInteger userListControllerIndex;

/*
 All user objects in this session:
  */
@property (strong, nonatomic, readonly) NSMutableArray * users;

/*
 Keys of all chats sorted by last message date:
  */
@property (strong, nonatomic, readonly) NSMutableArray * sortedChatKeys;

/*
 Keys of all users sorted by name:
  */
@property (strong, nonatomic, readonly) NSMutableArray * sortedUserKeys;


/* 
 The shared singleton instance:
  */
+ (ETRSessionManager *)sharedManager;

+ (ETRRoom *)sessionRoom;

/*
 Become a member of a room and start a new session.
 */
- (BOOL)startSession;

/*
 Remove user from the room, reset attributes and return to the room list.
 */
- (void)endSession;

/*
 Attempts to restore the last Session Room from Defaults;
 Does not start the Session;
 Start the Join View Controller to continue, if returning YES.
 
 Return: YES, if the Room has been restored
 */
- (BOOL)restoreSession;

/*
 Prepare the session manager so it can join a room later.
 */
- (void)prepareSessionInRoom:(ETRRoom *)room
        navigationController:(UINavigationController *)navigationController;

#pragma mark -
#pragma mark Regular User List Update

/*
 
 */
- (void)acknowledegeUserListUpdate;

/*
 
 */
- (BOOL)doUpdateUserList;

@end
