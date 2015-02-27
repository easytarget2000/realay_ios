//
//  ChatViewController.m
//  Realay
//
//  Created by Michel S on 01.12.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import "ETRChatViewController.h"

#import "ETRChatMessageCell.h"
#import "ETRUserListViewController.h"
#import "ETRAlertViewBuilder.h"
#import "ETRViewProfileViewController.h"
#import "ETRAction.h"

#define kIdentLeftMsgCell   @"strangeMsgCell"
#define kIdentMsgCell       @"myMsgCell"
#define kSegueToNext        @"chatToUserListSegue"
#define kSegueToProfile     @"chatToViewProfileSegue"

@implementation ETRChatViewController {
    BOOL allowDisappear;
}

# pragma mark - UIViewController

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    // Make sure the room manager meets the requirements for this view controller.
    if (![[ETRSession sharedSession] room] && ![[ETRSession sharedSession] didBeginSession]) {
        NSLog(@"ERROR: No Room object in manager or user did not join.");
        [[self navigationController] popViewControllerAnimated:NO];
        return;
    }
    
    if (![self chat]) {
        NSLog(@"ERROR: No chat object assigned to chat view controller.");
        [[self navigationController] popViewControllerAnimated:NO];
        return;
    }
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // Enable automatic scrolling.
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    
    // Tapping anywhere but the keyboard, hides it.
    UITapGestureRecognizer *tap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(dismissKeyboard)];
    [[self view] addGestureRecognizer:tap];

#ifdef DEBUG
    NSLog(@"INFO: Chat viewDidLoad %ld", [[self chat] chatID]);
#endif
    
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];
    
    // Assign delegates.
    [[ETRSession sharedSession] setChatDelegate:self];
    [[self messagesTableView] setDataSource:self];
    [[self messagesTableView] setDelegate:self];
    [[self messagesTableView] reloadData];
    [[self messageTextField] setDelegate:self];
    
    // Show no notifications for this chat.
    [[ETRSession sharedSession] setActiveChatID:[[self chat] chatID]];
    
    NSString *backButtonTitle;
    if ([self isPublic]) {
        // Public chat controller's title is the room title.
        [self setTitle:[[[ETRSession sharedSession] room] title]];
        //TODO: Localization
        backButtonTitle = @"Public";

    } else {
        // Private chat:
        
        // Display the chat partner as the title.
        [self setTitle:[[[self chat] partner] name]];
        // Remove the "Leave" button. Will automatically be replaced with back button.
        [[self navigationItem] setLeftBarButtonItem:nil];
        
        // The More button is a Profile button in private chats.
        NSString *profile = @"Profile";
        [[self moreButton] setTitle:profile];
        backButtonTitle = @"";
    }
    
    // Prepare the appropriate back button TO this view controller.
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:backButtonTitle
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:nil
                                                                  action:nil];
    [[self navigationItem] setBackBarButtonItem:backButton];
    
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
    
    // Fake a delegate call to get the initial messages.
    [self chatDidUpdateWithKey:[[self chat] dictKey]];
    
#ifdef DEBUG
    NSLog(@"\nINFO: ETRChatViewController viewDidAppear %ld, %ld",
          [[[ETRSession sharedSession] room] iden], [[self chat] chatID]);
#endif
    
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [self dismissKeyboard];
    
    // Disable delegates.
    [[ETRSession sharedSession] setChatDelegate:nil];
    [[self messageTextField] setDelegate:nil];
    
    // Show all notifications because no chat is visible.
    [[ETRSession sharedSession] setActiveChatID:-1];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];

#ifdef DEBUG
    NSLog(@"INFO: ETRChatViewController %ld viewWillDisappear finished.",
          [[self chat] chatID]);
#endif
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [[ETRSession sharedSession] didReceiveMemoryWarning];
}

#pragma mark - ETRRoomManagerDelegate

- (void)chatDidUpdateWithKey:(NSString *)chatKey {
    
    // Add new messages if any of them are for this chat controller.
    if ([chatKey isEqualToString:[[self chat] dictKey]]) {
        
        // Overwrite this controller's chat object with the updated one from the manager.
        ETRChat *updatedChat = [[ETRSession sharedSession] chatForKey:[[self chat] dictKey]];
        if (updatedChat) [self setChat:updatedChat];
        
        // Refresh the table and scroll down.
        [[self messagesTableView] reloadData];
        [self scrollDownTableViewAnimated:NO];
        
#ifdef DEBUG 
        NSLog(@"INFO: New messages arrived in %@, %ld.",
              chatKey, [[[ETRSession sharedSession] room] iden]);
#endif
    }

}

#pragma mark - IBAction

- (IBAction)sendButtonPressed:(id)sender {
    
    [self dismissKeyboard];
    
    // Get the message from the text field.
    NSString *typedString = [[[self messageTextField] text]
                             stringByTrimmingCharactersInSet:
                             [NSCharacterSet whitespaceCharacterSet]];
    
    if ([typedString length] > 0) {
        ETRAction *newMessage = [ETRAction outgoingMessage:typedString
                                                              inChat:[[self chat] chatID]];
        [newMessage insertMessageIntoDB];
    }
    
    [[self messageTextField] setText:@""];
}

- (IBAction)leaveButtonPressed:(id)sender {
    allowDisappear = YES;
    [ETRAlertViewBuilder showLeaveConfirmViewWithDelegate:self];
}

- (IBAction)moreButtonPressed:(id)sender {
    
    allowDisappear = YES;
    
    // The More button is a Profile button in private chats.
    if ([self isPublic]) {
        [self performSegueWithIdentifier:kSegueToNext sender:self];
    } else {
        [self performSegueWithIdentifier:kSegueToProfile sender:[[self chat] partner]];
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)myTableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Get the message for this particular cell.
    ETRAction *currentMsg = [[[self chat] messages] objectAtIndex:[indexPath row]];
    
    // Check if this is one of my sent messages.
    BOOL isMyMessage;
    isMyMessage = [[currentMsg sender] userID] == [[ETRLocalUser sharedLocalUser] userID];
    
    // Decide if this message needs a name label or not.
    BOOL showsSender = [self isPublic] && !isMyMessage;
    
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
    [msgCell applyMessage:currentMsg
                fitsWidth:self.view.frame.size.width
                 sentByMe:isMyMessage
              showsSender:showsSender];
    
    return msgCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ETRAction *currentMsg = [[[self chat] messages] objectAtIndex:[indexPath row]];
    if (currentMsg) {
        // Decide if this message needs a name label or not.
        BOOL hasNameLabel = [self isPublic]
        && ([[currentMsg sender] userID] != [[ETRLocalUser sharedLocalUser] userID]);
        
        CGFloat rowHeight = [currentMsg rowHeightForWidth:self.view.frame.size.width
                                             hasNameLabel:hasNameLabel];
        
//        [_rowHeights setObject:[NSNumber numberWithDouble:rowHeight]
//            atIndexedSubscript:[indexPath row]];
        
        return rowHeight;
    } else {
        return 0;
    }

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[self chat] messages] count];
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
        
#ifdef DEBUG
        NSLog(@"INFO: Scrolling %ld table to %ld", [[self chat] chatID], bottomRow);
#endif
    }
    
    allowDisappear = YES;
    
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[ETRSession sharedSession] endSession];
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
        
        ETRViewProfileViewController *destination = [segue destinationViewController];
        if ([sender isMemberOfClass:[ETRUser class]]) {
            [destination setUser:(ETRUser *)sender];
        }
        
    }
}

@end
