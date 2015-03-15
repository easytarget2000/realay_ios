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
#import "ETRCoreDataHelper.h"
#import "ETRDetailsViewController.h"
#import "ETRUser.h"
#import "ETRUserListViewController.h"
#import "ETRReadabilityHelper.h"
#import "ETRRoom.h"
#import "ETRSentMessageCell.h"
#import "ETRSession.h"

static NSString *const ETRConversationToUserListSegue = @"conversationToUserListSegue";

static NSString *const ETRConversationToProfileSegue = @"conversationToProfileSeuge";

static NSString *const ETRReceivedMessageCellIdentifier = @"receivedMessageCell";

static NSString *const ETRReceivedMediaCellIdentifier = @"receivedMediaCell";

static NSString *const ETRSentMessageCellIdentifier = @"sentMessageCell";

static NSString *const ETRSentMediaCellIdentifier = @"sentMediaCell";


@interface ETRConversationViewController ()

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic,retain) UIRefreshControl *historyControl;

@end


@implementation ETRConversationViewController

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
    
    [[self messagesTableView] reloadData];
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
    
    // Add a pull-down refreshControl
    [[self historyControl] addTarget:self
                              action:@selector(updateRoomsTable)
                    forControlEvents:UIControlEventValueChanged];
    
    if (_isPublic) {
        ETRRoom *sessionRoom;
        sessionRoom = [ETRSession sessionRoom];
        [[[self navigationItem] backBarButtonItem] setAction:@selector(backButtonPressed:)];
        [[self navigationController] setTitle:[sessionRoom title]];
    } else {
        
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [self dismissKeyboard];
    
    // Disable delegates.
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
    // TODO: Reset message limit.
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

#pragma mark -
#pragma mark Fetched Results Controller Delegate Methods
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [[self messagesTableView] beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [[self historyControl] endRefreshing];
    [[self messagesTableView] endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [[self messagesTableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                            withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [[self messagesTableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                            withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeUpdate: {
            // TODO: Determine if necessary.
        }
        case NSFetchedResultsChangeMove: {
            [[self messagesTableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                            withRowAnimation:UITableViewRowAnimationFade];
            [[self messagesTableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                            withRowAnimation:UITableViewRowAnimationFade];
        }
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
        if (_isPublic) {
            [ETRCoreDataHelper dispatchPublicMessage:typedString];
        } else {
            [ETRCoreDataHelper dispatchMessage:typedString toRecipient:_partner];
        }
    }
    
    [[self messageTextField] setText:@""];
}

- (void)backButtonPressed:(id)sender {
    [ETRAlertViewFactory showLeaveConfirmViewWithDelegate:self];
}

- (IBAction)moreButtonPressed:(id)sender {
    // The More button is a Profile button in private chats.
    if (_isPublic) {
        [self performSegueWithIdentifier:ETRConversationToUserListSegue
                                  sender:nil];
    } else {
        [self performSegueWithIdentifier:ETRConversationToProfileSegue
                                  sender:nil];
    }
}

#pragma mark -
#pragma mark Table View Data Source Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!_fetchedResultsController || ![[_fetchedResultsController fetchedObjects] count]) {
        return 1;
    }
    
    id<NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] != 0) {
        NSLog(@"ERROR: Invalid section in Conversation TableView: %ld", [indexPath row]);
        return [[UITableViewCell alloc] init];
    }
    
    if (!_fetchedResultsController || ![_fetchedResultsController fetchedObjects]) {
        return [[UITableViewCell alloc] init];
    }
    
    id<NSObject> record = [_fetchedResultsController objectAtIndexPath:indexPath];
    if (!record || ![record isKindOfClass:[ETRAction class]]) {
        NSLog(@"ERROR: Invalid record type at: %ld", [indexPath row]);
        return [[UITableViewCell alloc] init];
    }
    
    ETRAction *action = (ETRAction *)record;
    
    if ([action isPublicMessage]) {
        if ([action isPhotoMessage]) {
            return [tableView dequeueReusableCellWithIdentifier:ETRReceivedMediaCellIdentifier
                                            forIndexPath:indexPath];
        } else {
            return [tableView dequeueReusableCellWithIdentifier:ETRReceivedMessageCellIdentifier
                                                   forIndexPath:indexPath];
        }
    } else {
        if ([action isPhotoMessage]) {
            return [tableView dequeueReusableCellWithIdentifier:ETRSentMediaCellIdentifier
                                                   forIndexPath:indexPath];
        } else {
            ETRSentMessageCell *cell;
            cell = [tableView dequeueReusableCellWithIdentifier:ETRSentMessageCellIdentifier
                                                   forIndexPath:indexPath];
            
            [[cell messageLabel] setText:[action messageContent]];
            NSString *timestamp = [ETRReadabilityHelper formattedDate:[action sentDate]];
            [[cell timeLabel] setText:timestamp];
            return cell;
        }
    }
    
}

// Scroll to the bottom of a table.
- (void)scrollDownTableViewAnimated:(BOOL)animated {
    NSInteger bottomRow = [_messagesTableView numberOfRowsInSection:0] - 1;
    if (bottomRow >= 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:bottomRow inSection:0];
        [[self messagesTableView] scrollToRowAtIndexPath:indexPath
                                        atScrollPosition:UITableViewScrollPositionMiddle
                                                animated:animated];

    }

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
    id destination = [segue destinationViewController];
    
    if ([destination isKindOfClass:[ETRDetailsViewController class]]) {
        ETRDetailsViewController *detailsViewController;
        detailsViewController = (ETRDetailsViewController *)destination;
        if ([sender isMemberOfClass:[ETRUser class]]) {
            [detailsViewController setUser:(ETRUser *)sender];
        }
    }
}

@end
