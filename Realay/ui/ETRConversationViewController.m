//
//  ChatViewController.m
//  Realay
//
//  Created by Michel S on 01.12.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import "ETRConversationViewController.h"

#import "ETRAction.h"
#import "ETRActionManager.h"
#import "ETRAnimator.h"
#import "ETRAlertViewFactory.h"
#import "ETRConversation.h"
#import "ETRCoreDataHelper.h"
#import "ETRDefaultsHelper.h"
#import "ETRDetailsViewController.h"
#import "ETRImageEditor.h"
#import "ETRImageLoader.h"
#import "ETRUser.h"
#import "ETRReceivedMediaCell.h"
#import "ETRReceivedMessageCell.h"
#import "ETRReadabilityHelper.h"
#import "ETRRoom.h"
#import "ETRSentMediaCell.h"
#import "ETRSentMessageCell.h"
#import "ETRSessionManager.h"
#import "ETRUIConstants.h"
#import "ETRUser.h"


static CGFloat const ETREstimatedMessageRowHeight = 100.0f;

static NSString *const ETRConversationToUserListSegue = @"PublicChatToSessionTabs";

static NSString *const ETRConversationToProfileSegue = @"ChatToProfile";

static NSString *const ETRReceivedMessageCellIdentifier = @"receivedMessageCell";

static NSString *const ETRReceivedMediaCellIdentifier = @"receivedMediaCell";

static NSString *const ETRSentMessageCellIdentifier = @"sentMessageCell";

static NSString *const ETRSentMediaCellIdentifier = @"sentMediaCell";

static int const ETRMessagesLimitStep = 20;


@interface ETRConversationViewController ()
<
ETRInternalNotificationHandler,
NSFetchedResultsControllerDelegate,
UIImagePickerControllerDelegate,
UINavigationControllerDelegate,
UITableViewDataSource,
UITableViewDelegate,
UITextFieldDelegate
>

/*
 
 */
@property (strong, nonatomic) NSFetchedResultsController * fetchedResultsController;

/*
 
 */
@property (nonatomic,retain) UIRefreshControl * historyControl;

/*
 
 */
@property (nonatomic) BOOL didFirstScrolldown;

/*
 
 */
@property (nonatomic) NSUInteger messagesLimit;

@end


@implementation ETRConversationViewController

# pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self verifySession];
     
    // Enable automatic scrolling.
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    
    // Tapping anywhere but the keyboard, hides it.
    UITapGestureRecognizer * tap;
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                  action:@selector(dismissKeyboard)];
    [[self view] addGestureRecognizer:tap];
    
    // Do not display empty cells at the end.
    [[self messagesTableView] setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    [[self messagesTableView] setRowHeight:UITableViewAutomaticDimension];
    [[self messagesTableView] setEstimatedRowHeight:ETREstimatedMessageRowHeight];
    
    // Add a long press Recognizer to the Table.
    UILongPressGestureRecognizer * recognizer;
    recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [recognizer setMinimumPressDuration:0.8];
    [[self messagesTableView] addGestureRecognizer:recognizer];
    
    // Initialize the Fetched Results Controller
    // that is going to load and monitor message records.
    _messagesLimit = 30L;
    [self setUpFetchedResultsController];
    
    // Configure Views depending on purpose of this Conversation.
    if (_isPublic) {
        ETRRoom * sessionRoom;
        sessionRoom = [ETRSessionManager sessionRoom];
        [self setTitle:[sessionRoom title]];

        [[self navigationItem] setHidesBackButton:YES];
        UIBarButtonItem * exitButton;
        exitButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Leave", @"Exit Session")
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(exitButtonPressed:)];
        [[self navigationItem] setLeftBarButtonItem:exitButton];
        
        // Only Public Conversations have a badge in the Navigation Bar.
//        [[[self navigationController] navigationBar] addSubview:[self badgeLabel]];
        
        // Only public Conversations get a BackBarButton that has a title (in the _next_ ViewController).
        NSString * returnTitle = NSLocalizedString(@"Chat", @"(Public) Chat");
        [[[self navigationItem] backBarButtonItem] setTitle:returnTitle];
    } else if (_partner) {
        [self setTitle:[_partner name]];
        [[self moreButton] setTitle:NSLocalizedString(@"Profile", @"User Profile")];
        [[self messagesTableView] setBackgroundColor:[ETRUIConstants secondaryBackgroundColor]];
    }
    
    // Configure manual refresher.
    _historyControl = [[UIRefreshControl alloc] init];
    [_historyControl addTarget:self
                       action:@selector(extendHistory)
             forControlEvents:UIControlEventValueChanged];
    [_historyControl setTintColor:[ETRUIConstants accentColor]];
    NSString * pullDownText = NSLocalizedString(@"Pull_down_load_older", @"Load old messages");
    [_historyControl setAttributedTitle:[[NSAttributedString alloc] initWithString:pullDownText]];
    [[self messagesTableView] addSubview:_historyControl];
    
    _didFirstScrolldown = NO;
    [[self mediaButton] setTintColor:[UIColor whiteColor]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[self galleryButton] setHidden:YES];
    [[self cameraButton] setHidden:YES];
    
    // Listen for keyboard changes.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    // Reset Bar elements that might have been changed during navigation to other View Controllers.
    [[self navigationController] setToolbarHidden:YES];
    [[[self navigationController] navigationBar] setTranslucent:NO];
    
    NSNumber * conversationID;
    if (_isPublic) {
        ETRRoom * sessionRoom;
        sessionRoom = [ETRSessionManager sessionRoom];
        [[self navigationController] setTitle:[sessionRoom title]];
        conversationID = @(ETRActionPublicUserID);
    } else if (_partner) {
        [[self navigationController] setTitle:[_partner name]];
        conversationID = [_partner remoteID];
    } else {
        [[self navigationController] popToRootViewControllerAnimated:YES];
        return;
    }
    
    [[ETRActionManager sharedManager] setForegroundPartnerID:conversationID];
    
    // Restore any unsent message input.
    NSString * lastText = [ETRDefaultsHelper messageInputTextForConversationID:conversationID];
    [[self messageInputView] setText:lastText];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[self messagesTableView] reloadData];
    
    [self verifySession];
    [self updateConversationStatus];
    
    if (_isPublic) {
        // The first time a public Conversation is shown,
        // ask for Notification Permissions.
        
        UIUserNotificationType types;
        types = UIUserNotificationTypeBadge | UIUserNotificationTypeAlert | UIUserNotificationTypeSound;
        UIUserNotificationSettings * settings;
        settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        
        // Public Conversations have a Badge
        // that shows the number of unread private messages.
        [[ETRActionManager sharedManager] setInternalNotificationHandler:self];
    }
    
    if (!_didFirstScrolldown) {
        [self scrollDownTableViewAnimated];
        _didFirstScrolldown = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self dismissKeyboard];
    
    // Disable delegates.
    [[self messageInputView] setDelegate:nil];
    
    // Show all notifications because no chat is visible.
    [[ETRSessionManager sharedManager] setActiveChatID:-1];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    
    // Store unset message input.
    NSNumber * conversationID;
    if (_isPublic) {
        conversationID = @(ETRActionPublicUserID);
    } else if (_partner && [[self messagesTableView] numberOfRowsInSection:0] > 0) {
        conversationID = [_partner remoteID];
        
        // Acknowledge that all messages have been read in this Private Conversation.
        ETRConversation * conversation;
        conversation = [ETRCoreDataHelper conversationWithPartner:_partner];
        [conversation setHasUnreadMessage:@(NO)];
        [ETRCoreDataHelper saveContext];
    }
    [ETRDefaultsHelper storeMessageInputText:[[self messageInputView] text]
                           forConversationID:conversationID];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // TODO: Reset message limit.
}

#pragma mark -
#pragma mark Session Events

- (BOOL)verifySession {
    if (!_isPublic && !_partner) {
        NSLog(@"ERROR: No Conversation found.");
        [[ETRSessionManager sharedManager] endSession];
        [[self navigationController] popToRootViewControllerAnimated:YES];
        return NO;
    }
    
    // Make sure the room manager meets the requirements for this view controller.
    if (![ETRSessionManager sessionRoom] || ![[ETRSessionManager sharedManager] didStartSession]) {
        NSLog(@"ERROR: No Room object in manager or user did not join.");
        [[ETRSessionManager sharedManager] endSession];
        [[self navigationController] popToRootViewControllerAnimated:YES];
        return NO;
    }
    
    return YES;
}

- (BOOL)updateConversationStatus {
    if (_partner) {
        if (![[ETRSessionManager sessionRoom] isEqual:[_partner inRoom]]) {
            [ETRAlertViewFactory showHasLeftViewForUser:_partner];
            return NO;
        }
    }
    
    [[self inputCover] setHidden:YES];
    return YES;
}

- (void)setPrivateMessagesBadgeNumber:(NSInteger)number {
    if (_partner) {
        // Private Conversations do not display a badge.
        [[self badgeLabel] setHidden:YES];
        return;
    }
    
    [super setPrivateMessagesBadgeNumber:number
                                 inLabel:[self badgeLabel]
                          animateFromTop:YES];
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
#pragma mark Fetched Results Controller

- (void)setUpFetchedResultsController {
    if (_isPublic) {
        _fetchedResultsController = [ETRCoreDataHelper publicMessagesResultsControllerWithDelegate:self
                                                                              numberOfLastMessages:_messagesLimit];
    } else if (_partner) {
        _fetchedResultsController = [ETRCoreDataHelper messagesResultsControllerForPartner:_partner
                                                                      numberOfLastMessages:_messagesLimit
                                                                                  delegate:self];
    }
    
    NSError * error = nil;
    [_fetchedResultsController performFetch:&error];
    if (error) {
        NSLog(@"ERROR: performFetch: %@", error);
    }
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [[self messagesTableView] beginUpdates];
    [[self historyControl] endRefreshing];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [[self messagesTableView] endUpdates];
    
//    [self scrollDownTableViewAnimated];
    _didFirstScrolldown = YES;
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
//    NSLog(@"didChangeObject atIndexPath:%@ forChangeType:%lu newIndexPath:%@", indexPath, (unsigned long)type, newIndexPath);
    
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
            [[self messagesTableView] cellForRowAtIndexPath:indexPath];
//            NSLog(@"Updated message record: %ld, %ld, %@", [indexPath row], [newIndexPath row], anObject);
            break;
        }
        case NSFetchedResultsChangeMove: {
            [[self messagesTableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                            withRowAnimation:UITableViewRowAnimationFade];
            [[self messagesTableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                            withRowAnimation:UITableViewRowAnimationFade];
        }
    }
//    [[self messagesTableView] reloadData];
//    [self scrollDownTableViewAnimated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = [[_fetchedResultsController fetchedObjects] count];
    
    if (numberOfRows < 1) {
        [[self infoLabel] setHidden:NO];
    } else if (![[self infoLabel] isHidden]){
        [ETRAnimator fadeView:[self infoLabel] doAppear:NO completion:nil];
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] != 0) {
        NSLog(@"ERROR: Invalid section in Conversation TableView: %d", (int) [indexPath row]);
        return [[UITableViewCell alloc] init];
    }
    
    if (!_fetchedResultsController || ![_fetchedResultsController fetchedObjects]) {
        return [[UITableViewCell alloc] init];
    }
    
    ETRAction * action = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    if ([action isSentAction]) {
        if ([action isPhotoMessage]) {
            ETRSentMediaCell * cell;
            cell = [tableView dequeueReusableCellWithIdentifier:ETRSentMediaCellIdentifier
                                                   forIndexPath:indexPath];
            [ETRImageLoader loadImageForObject:action
                                      intoView:[cell iconView]
                              placeHolderImage:[UIImage imageNamed:ETRImageNameImagePlaceholder]
                                   doLoadHiRes:NO];
            NSString * timestamp = [ETRReadabilityHelper formattedDate:[action sentDate]];
            [[cell timeLabel] setText:timestamp];
            if (_partner) {
                [cell setBackgroundColor:[ETRUIConstants secondaryBackgroundColor]];
            }
            return cell;
        } else {
            ETRSentMessageCell * cell;
            cell = [tableView dequeueReusableCellWithIdentifier:ETRSentMessageCellIdentifier
                                                   forIndexPath:indexPath];
            
            [[cell messageLabel] setText:[action messageContent]];
            NSString * timestamp = [ETRReadabilityHelper formattedDate:[action sentDate]];
            [[cell timeLabel] setText:timestamp];
            if (_partner) {
                [cell setBackgroundColor:[ETRUIConstants secondaryBackgroundColor]];
            }
            return cell;
        }
    } else {
        ETRUser * sender = [action sender];
        NSString * senderName;
        if (_isPublic) {
            if (sender && [sender name]) {
                senderName = [sender name];
            } else {
                senderName = @"n/a";
            }
        }
        
        if ([action isPhotoMessage]) {
            ETRReceivedMediaCell * cell;
            cell = [tableView dequeueReusableCellWithIdentifier:ETRReceivedMediaCellIdentifier
                                                   forIndexPath:indexPath];
            [ETRImageLoader loadImageForObject:[action sender]
                                      intoView:[cell userIconView]
                              placeHolderImage:[UIImage imageNamed:ETRImageNameUserIcon]
                                   doLoadHiRes:NO];
            if (_isPublic) {
                [[cell nameLabel] setText:senderName];
            } else {
                [[cell nameLabel] setHidden:YES];
//                [[cell nameLabel] setConstr];
            }
            [ETRImageLoader loadImageForObject:action
                                      intoView:[cell iconView]
                              placeHolderImage:[UIImage imageNamed:ETRImageNameImagePlaceholder]
                                   doLoadHiRes:NO];
            
            NSString * timestamp = [ETRReadabilityHelper formattedDate:[action sentDate]];
            [[cell timeLabel] setText:timestamp];
            if (_partner) {
                [cell setBackgroundColor:[ETRUIConstants secondaryBackgroundColor]];
            }
            return cell;
        } else {
            ETRReceivedMessageCell * cell;
            cell = [tableView dequeueReusableCellWithIdentifier:ETRReceivedMessageCellIdentifier
                                                   forIndexPath:indexPath];
            
            [ETRImageLoader loadImageForObject:[action sender]
                                      intoView:[cell userIconView]
                              placeHolderImage:[UIImage imageNamed:ETRImageNameUserIcon]
                                   doLoadHiRes:NO];
            if (_isPublic) {
                [[cell nameLabel] setText:senderName];
            } else {
                [[cell nameLabel] removeFromSuperview];
            }
            
            [[cell nameLabel] setText:senderName];
            
            [[cell messageLabel] setText:[action messageContent]];
            NSString * timestamp = [ETRReadabilityHelper formattedDate:[action sentDate]];
            [[cell timeLabel] setText:timestamp];
            if (_partner) {
                [cell setBackgroundColor:[ETRUIConstants secondaryBackgroundColor]];
            }
            return cell;
        }
    }
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self hideMediaMenu];
}

/*
 Scrolls to the bottom of a table
 */
- (void)scrollDownTableViewAnimated {
    dispatch_after(
                   800,
                   dispatch_get_main_queue(),
                   ^{
                       NSInteger bottomRow;
                       bottomRow = [_messagesTableView numberOfRowsInSection:0] - 1;
                       if (bottomRow >= 0) {
                           NSIndexPath * indexPath;
                           indexPath = [NSIndexPath indexPathForRow:bottomRow inSection:0];
                           [[self messagesTableView] scrollToRowAtIndexPath:indexPath
                                                           atScrollPosition:UITableViewScrollPositionBottom
                                                                   animated:YES];
                       }
                   });
}

- (void)extendHistory {
    // Increase the message limit and request a new Results Controller.
    _messagesLimit += ETRMessagesLimitStep;
    
    [self setUpFetchedResultsController];
    [[self messagesTableView] reloadData];
    [[self historyControl] endRefreshing];
}

#pragma mark -
#pragma mark Message Long Press

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
        CGPoint point = [gestureRecognizer locationInView:[self messagesTableView]];
        NSIndexPath * indexPath = [[self messagesTableView] indexPathForRowAtPoint:point];
        
        ETRAction * record = [_fetchedResultsController objectAtIndexPath:indexPath];
        [[self alertHelper] showMenuForMessage:record calledByViewController:self];
    }
}


#pragma mark -
#pragma mark Input

- (IBAction)sendButtonPressed:(id)sender {
    [self dismissKeyboard];
    
    if (![self updateConversationStatus]) {
        return;
    }
    
    // Get the message from the text field.
    NSString * typedString = [[[self messageInputView] text]
                             stringByTrimmingCharactersInSet:
                             [NSCharacterSet whitespaceCharacterSet]];
    
    if ([typedString length] > 0) {
        if (_isPublic) {
            [ETRCoreDataHelper dispatchPublicMessage:typedString];
        } else {
            [ETRCoreDataHelper dispatchMessage:typedString toRecipient:_partner];
        }
    }
    
    [[self messageInputView] setText:@""];
}

- (IBAction)mediaButtonPressed:(id)sender {
    // If the lower button, the camera button, is hidden, open the menu.
    
    if ([[self cameraButton] isHidden]) {
        if (![self updateConversationStatus]) {
            return;
        }
        
        // Expand the menu from the bottom.
        [ETRAnimator toggleBounceInView:[self cameraButton]
                         animateFromTop:NO
                             completion:^{
                                 [ETRAnimator toggleBounceInView:[self galleryButton]
                                                  animateFromTop:NO
                                                      completion:nil];
                             }];
        
        // Replace the icon with an arrow and rotate it.
        [[self mediaButton] setImage:[UIImage imageNamed:ETRImageNameArrowRight]];
        [UIView animateWithDuration:0.5
                         animations:^{
                             CGAffineTransform transform;
                             transform = CGAffineTransformMakeRotation(-90.0f * M_PI_4);
                             [[self mediaButton] setTransform:transform];
                         }];
    } else {
        [self hideMediaMenu];
    }
}

/*
 Closes the menu, if the upper button, the gallery button, is visible
 */
- (void)hideMediaMenu {
    //    [self updateConversationStatus];
    
    if(![[self galleryButton] isHidden]) {
        // Collapse the menu from the top.
        [ETRAnimator toggleBounceInView:[self galleryButton]
                         animateFromTop:NO
                             completion:^{
                                 [ETRAnimator toggleBounceInView:[self cameraButton]
                                                  animateFromTop:NO
                                                      completion:nil];
        }];
        
        // Rotate the arrow back and show the default icon when finished.
        [UIView animateWithDuration:0.5
                         animations:^{
                             CGAffineTransform transform;
                             transform = CGAffineTransformMakeRotation(0.0f);
                             [[self mediaButton] setTransform:transform];
                         }
                         completion:^(BOOL finished) {
                             [[self mediaButton] setImage:[UIImage imageNamed:ETRImageNameAttachFile]];
                         }];
    }
}

- (IBAction)galleryButtonPressed:(id)sender {
    [[self galleryButton] setHidden:YES];
    [[self cameraButton] setHidden:YES];
    
    UIImagePickerController * picker = [[UIImagePickerController alloc] init];
    [picker setDelegate:self];
    [picker setSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    [picker setAllowsEditing:YES];
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)cameraButtonPressed:(id)sender {
    [[self galleryButton] setHidden:YES];
    [[self cameraButton] setHidden:YES];
    
    UIImagePickerController * picker = [[UIImagePickerController alloc] init];
    [picker setDelegate:self];
    [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if (_isPublic) {
        [ETRCoreDataHelper dispatchPublicImageMessage:[ETRImageEditor imageFromPickerInfo:info]];
    } else if (_partner) {
        [ETRCoreDataHelper dispatchImageMessage:[ETRImageEditor imageFromPickerInfo:info]
                                    toRecipient:_partner];
    }
}

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    [[navigationController navigationBar] setBarStyle:UIBarStyleBlack];
}

#pragma mark - Keyboard Notifications

- (void)dismissKeyboard {
    [[self messageInputView] resignFirstResponder];
    [self hideMediaMenu];
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
    [self scrollDownTableViewAnimated];
}

#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendButtonPressed:nil];
    return YES;
}

#pragma mark - Navigation

- (IBAction)moreButtonPressed:(id)sender {
    // The More button is a Profile button in private chats.
    if (_isPublic) {
        
        if (![[self badgeLabel] isHidden]) {
            [ETRAnimator moveView:[self badgeLabel]
                   toDisappearAtY:(self.view.frame.size.height + 100.0f)
                       completion:^{
                           [self performSegueWithIdentifier:ETRConversationToUserListSegue
                                                     sender:nil];
                       }];
        } else {
            [self performSegueWithIdentifier:ETRConversationToUserListSegue
                                      sender:nil];
        }
        
        
    } else {
        [self performSegueWithIdentifier:ETRConversationToProfileSegue
                                  sender:_partner];
    }
}

- (void)exitButtonPressed:(id)sender {
    [[self alertHelper] showLeaveConfirmView];
}

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
