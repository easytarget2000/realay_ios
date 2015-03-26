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
@property (nonatomic, readonly) BOOL didBeginSession;

/*
 Return to this view when clicking the map button after joining.
  */
@property (nonatomic) NSInteger mapControllerIndex;

///*
// Font that is to be used for the sender label of a message:
//  */
//@property (strong, nonatomic, readonly) UIFont *msgSenderFont;
//
///*
// Font that is to be used for the message itself:
//  */
//@property (strong, nonatomic, readonly) UIFont *msgTextFont;

/*
 Session is able to push/pop view controller.
  */
@property (strong, nonatomic) UINavigationController *navigationController;

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
@property (strong, nonatomic, readonly) NSMutableArray *users;

/*
 Keys of all chats sorted by last message date:
  */
@property (strong, nonatomic, readonly) NSMutableArray *sortedChatKeys;

/*
 Keys of all users sorted by name:
  */
@property (strong, nonatomic, readonly) NSMutableArray *sortedUserKeys;


/* 
 The shared singleton instance:
  */
+ (ETRSessionManager *)sharedManager;

+ (ETRRoom *)sessionRoom;

/*
 To be called by view controllers receiving memory warnings.
 */
- (void)didReceiveMemoryWarning;

/*
 Become a member of a room and start a new session.
 */
- (BOOL)startSession;

/*
 Remove user from the room, reset attributes and return to the room list.
 */
- (void)endSession;

/*
 Prepare the session manager so it can join a room later.
 */
- (void)prepareSessionInRoom:(ETRRoom *)room
        navigationController:(UINavigationController *)navigationController;

@end
