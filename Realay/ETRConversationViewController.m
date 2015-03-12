//
//  ChatViewController.m
//  Realay
//
//  Created by Michel S on 01.12.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import "ETRConversationViewController.h"

#import "ETRAction.h"
#import "ETRAlertViewFactory.h"
#import "ETRChatMessageCell.h"
#import "ETRDetailsViewController.h"
#import "ETRUserListViewController.h"
#import "ETRUser.h"

#import "ETRSharedMacros.h"

#define kIdentLeftMsgCell   @"strangeMsgCell"
#define kIdentMsgCell       @"myMsgCell"
#define kSegueToNext        @"chatToUserListSegue"
#define kSegueToProfile     @"chatToViewProfileSegue"

@implementation ETRConversationViewController {
    BOOL allowDisappear;
}

# pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (![self verifySession]) {
        return;
    }
     
    // Enable automatic scrolling.
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    
    // Tapping anywhere but the keyboard, hides it.
    UITapGestureRecognizer *tap;
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                  action:@selector(dismissKeyboard)];
    [[self view] addGestureRecognizer:tap];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![self verifySession]) {
        return;
    }
    
    if (_isPublic) {
        ETRRoom *sessionRoom;
        sessionRoom = [[ETRSession sharedManager] room];
        [[[self navigationItem] backBarButtonItem] setAction:@selector(backButtonPressed:)];
        [[self navigationController] setTitle:[sessionRoom title]];
    } else {
        
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Assign delegates.
    // TODO: Assign Session & Location delegates to
    [[self messagesTableView] setDataSource:self];
    [[self messagesTableView] setDelegate:self];
    [[self messagesTableView] reloadData];
    [[self messageTextField] setDelegate:self];
    
    // TODO: Tell Actions Manager that this View Controller is visible
    // to avoid obsolete Notifications.
    
    // TODO: Prepare the appropriate back button TO this view controller.

//    NSString *backButtonTitle;
//    if (_conversationID == kPublicReceiverID) {
//        // Public chat controller's title is the room title.
//        [self setTitle:[[[ETRSession sharedManager] room] title]];
//        //TODO: Localization
//        backButtonTitle = @"Public";
//    } else {
//        // Private chat:
//        
//        // TODO: Query the UserCache and display the chat partner as the title.
//        // Remove the "Leave" button. Will automatically be replaced with back button.
//        [[self navigationItem] setLeftBarButtonItem:nil];
//        
//        // The More button is a Profile button in private chats.
//        NSString *profile = @"Profile";
//        [[self moreButton] setTitle:profile];
//        backButtonTitle = @"";
//    }
//    
//    UIBarButtonItem *backButton;
//    backButton = [[UIBarButtonItem alloc] initWithTitle:backButtonTitle
//                                                  style:UIBarButtonItemStylePlain
//                                                 target:nil
//                                                 action:nil];
//    [[self navigationItem] setBackBarButtonItem:backButton];
    
    // Listen for keyboard changes.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    // Just in case there is a toolbar wanting to be displayed:
    [[self navigationController] setToolbarHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [self dismissKeyboard];
    
    // Disable delegates.
    [[ETRSession sharedManager] setChatDelegate:nil];
    [[self messageTextField] setDelegate:nil];
    
    // Show all notifications because no chat is visible.
    [[ETRSession sharedManager] setActiveChatID:-1];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [[ETRSession sharedManager] didReceiveMemoryWarning];
}

- (BOOL)verifySession {
    if (!_isPublic && !_partner) {
        NSLog(@"ERROR: Private Conversation requires a partner User.");
        [[ETRSession sharedManager] endSession];
        [[self navigationController] popToRootViewControllerAnimated:YES];
        return NO;
    }
    
    // Make sure the room manager meets the requirements for this view controller.
    if (![[ETRSession sharedManager] room] && ![[ETRSession sharedManager] didBeginSession]) {
        NSLog(@"ERROR: No Room object in manager or user did not join.");
        [[ETRSession sharedManager] endSession];
        [[self navigationController] popToRootViewControllerAnimated:YES];
        return NO;
    }
    
    return YES;
}

#pragma mark -
#pragma mark Public/Private Conversation Definition

- (void)setIsPublic:(BOOL)isPublic {
    _partner = nil;
    _isPublic = isPublic;
}

- (void)setPartner:(ETRUser *)partner {
    _isPublic = NO;
    _partner = partner;
}

#pragma mark - ETRRoomManagerDelegate

- (void)chatDidUpdateWithKey:(NSString *)chatKey {
    
//    // Add new messages if any of them are for this chat controller.
//    if ([chatKey isEqualToString:[[self chat] dictKey]]) {
//        
//        // Overwrite this controller's chat object with the updated one from the manager.
//        ETRChat *updatedChat = [[ETRSession sharedManager] chatForKey:[[self chat] dictKey]];
//        if (updatedChat) [self setChat:updatedChat];
//        
//        // Refresh the table and scroll down.
//        [[self messagesTableView] reloadData];
//        [self scrollDownTableViewAnimated:NO];
//        
//#ifdef DEBUG 
//        NSLog(@"INFO: New messages arrived in %@, %ld.",
//              chatKey, [[[ETRSession sharedManager] room] iden]);
//#endif
//    }

}

#pragma mark - IBAction

- (IBAction)sendButtonPressed:(id)sender {
    [self dismissKeyboard];
    
    // Get the message from the text field.
    NSString *typedString = [[[self messageTextField] text]
                             stringByTrimmingCharactersInSet:
                             [NSCharacterSet whitespaceCharacterSet]];
    
    if ([typedString length] > 0) {
//        ETRAction *newMessage = [ETRAction outgoingMessage:typedString toRecipient:_conversationID];
    }
    
    [[self messageTextField] setText:@""];
}

- (void)backButtonPressed:(id)sender {
    allowDisappear = YES;
    [ETRAlertViewFactory showLeaveConfirmViewWithDelegate:self];
}

- (IBAction)moreButtonPressed:(id)sender {
    allowDisappear = YES;
    
    // The More button is a Profile button in private chats.
    if (_isPublic) {
        [self performSegueWithIdentifier:kSegueToNext sender:nil];
    } else {
        [self performSegueWithIdentifier:kSegueToProfile sender:nil];
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)myTableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Get the message for this particular cell.
    ETRAction *message;
    
    // Decide if this message needs a name label or not.
//    BOOL showsSender = [self isPublic] && [message senderID] != [[ETRLocalUserManager sharedManager] userID];
    
    // Get the cell with the identifier.
    ETRChatMessageCell *msgCell;
    msgCell = [myTableView dequeueReusableCellWithIdentifier:kIdentMsgCell];
    
    // If the cell does not exist yet, set the views up programatically.
    if (!msgCell) {
        msgCell = [[ETRChatMessageCell alloc] initWithStyle:UITableViewCellStyleDefault
                                            reuseIdentifier:kIdentMsgCell];
    }
    
    // Apply the message and current view width to the cell.
    // It will calculate the bubble size and display the message.
    [msgCell applyMessage:message
                fitsWidth:self.view.frame.size.width];
    
    return msgCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    ETRAction *message = [[[self chat] messages] objectAtIndex:[indexPath row]];
//    if (message) {
//        // Decide if this message needs a name label or not.
//        BOOL hasNameLabel = [self isPublic] || ([message senderID] == [[ETRLocalUserManager sharedManager] userID]);
//        
//        CGFloat rowHeight = [message rowHeightForWidth:self.view.frame.size.width
//                                             hasNameLabel:hasNameLabel];
//        
////        [_rowHeights setObject:[NSNumber numberWithDouble:rowHeight]
////            atIndexedSubscript:[indexPath row]];
//        
//        return rowHeight;
//    }
    
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Scroll to the bottom of a table.
- (void)scrollDownTableViewAnimated:(BOOL)animated {
    if (!self) {
        return;
    }
    
    NSInteger bottomRow = [_messagesTableView numberOfRowsInSection:0] - 1;
    if (bottomRow >= 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:bottomRow inSection:0];
        [[self messagesTableView] scrollToRowAtIndexPath:indexPath
                                        atScrollPosition:UITableViewScrollPositionMiddle
                                                animated:animated];

    }
    
    allowDisappear = YES;
    
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[ETRSession sharedManager] endSession];
    }
}

#pragma mark - Keyboard Notifications

- (void)dismissKeyboard {
    [[self messageTextField] resignFirstResponder];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    allowDisappear = NO;
    [self resizeViewWithOptions:[notification userInfo]];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self resizeViewWithOptions:[notification userInfo]];
}

- (void)resizeViewWithOptions:(NSDictionary *)options {

    // Get the animation values.
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardEndFrame;
    [[options objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[options objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[options objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    
    // Apply the animation values.
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:)];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDuration:animationDuration];
    
    // Shrink the height of the view.
    CGRect viewFrame = [[self view] frame];
    CGRect keyboardEndFrameRelative = [[self view] convertRect:keyboardEndFrame fromView:nil];
    viewFrame.size.height = keyboardEndFrameRelative.origin.y;
    [[self view] setFrame:viewFrame];

    [UIView commitAnimations];
    allowDisappear = YES;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    [self scrollDownTableViewAnimated:YES];
}

#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendButtonPressed:nil];
    return YES;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:kSegueToProfile]) {
        
        ETRDetailsViewController *destination = [segue destinationViewController];
        if ([sender isMemberOfClass:[ETRUser class]]) {
            [destination setUser:(ETRUser *)sender];
        }
        
    }
}

@end
