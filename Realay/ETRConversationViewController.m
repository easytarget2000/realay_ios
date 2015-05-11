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

static NSString *const ETRConversationToUserListSegue = @"conversationToUserListSegue";

static NSString *const ETRConversationToProfileSegue = @"conversationToProfileSegue";

static NSString *const ETRReceivedMessageCellIdentifier = @"receivedMessageCell";

static NSString *const ETRReceivedMediaCellIdentifier = @"receivedMediaCell";

static NSString *const ETRSentMessageCellIdentifier = @"sentMessageCell";

static NSString *const ETRSentMediaCellIdentifier = @"sentMediaCell";


@interface ETRConversationViewController ()
<
NSFetchedResultsControllerDelegate,
UIImagePickerControllerDelegate,
UINavigationControllerDelegate,
UITableViewDataSource,
UITableViewDelegate,
UITextFieldDelegate
>

@property (strong, nonatomic) ETRAlertViewFactory * alertViewFactory;

@property (strong, nonatomic) NSFetchedResultsController * fetchedResultsController;

@property (nonatomic,retain) UIRefreshControl * historyControl;

@end


@implementation ETRConversationViewController

# pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self verifySession];
     
    // Enable automatic scrolling.
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    
    // Tapping anywhere but the keyboard, hides it.
    UITapGestureRecognizer *tap;
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
//    [recognizer setDelegate:self];
    [[self messagesTableView] addGestureRecognizer:recognizer];
    
    // Initialize the Fetched Results Controller
    // that is going to load and monitor message records.
    if (_isPublic) {
        ETRRoom * sessionRoom;
        sessionRoom = [ETRSessionManager sessionRoom];
        [self setTitle:[sessionRoom title]];
       _fetchedResultsController = [ETRCoreDataHelper publicMessagesResultsControllerWithDelegage:self];
        [[self navigationItem] setHidesBackButton:YES];
        UIBarButtonItem * exitButton;
        exitButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Leave", @"Exit Session")
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(exitButtonPressed:)];
        [[self navigationItem] setLeftBarButtonItem:exitButton];
        
        // Only public Conversations get a BackBarButton that has a title (in the _next_ ViewController).
        NSString * returnTitle = NSLocalizedString(@"Chat", @"(Public) Chat");
        [[[self navigationItem] backBarButtonItem] setTitle:returnTitle];
    } else if (_partner) {
        [self setTitle:[_partner name]];
        _fetchedResultsController = [ETRCoreDataHelper messagesResultsControllerForPartner:_partner
                                                                              withDelegate:self];
        [[self moreButton] setTitle:NSLocalizedString(@"Profile", @"User Profile")];
    }
    NSError *error = nil;
    [_fetchedResultsController performFetch:&error];
    if (error) {
        NSLog(@"ERROR: performFetch: %@", error);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Assign delegates.
    // TODO: Assign Session & Location delegates to
//    [[self messagesTableView] setDataSource:self];
//    [[self messagesTableView] setDelegate:self];
//    [[self messageTextField] setDelegate:self];
    
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
    
    // Reset Bar elements that might have been changed during navigation to other View Controllers.
    [[self navigationController] setToolbarHidden:YES];
    [[[self navigationController] navigationBar] setTranslucent:NO];
    
    // Add a pull-down refreshControl
    [[self historyControl] addTarget:self
                              action:@selector(updateRoomsTable)
                    forControlEvents:UIControlEventValueChanged];
    
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
         
    [[ETRActionManager sharedManager] setForegroundPartnerID:[conversationID longValue]];
         
    // Restore any unsent message input.
    NSString * lastText = [ETRDefaultsHelper messageInputTextForConversationID:conversationID];
    [[self messageTextField] setText:lastText];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[self messagesTableView] reloadData];
    [self scrollDownTableViewAnimated:YES];
    
    [self verifySession];
    [self updateConversationStatus];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self dismissKeyboard];
    
    // Disable delegates.
    [[self messageTextField] setDelegate:nil];
    
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
    } else if (_partner) {
        conversationID = [_partner remoteID];
    }
    [ETRDefaultsHelper storeMessageInputText:[[self messageTextField] text]
                           forConversationID:conversationID];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [[ETRSessionManager sharedManager] didReceiveMemoryWarning];
    // TODO: Reset message limit.
}

- (BOOL)verifySession {
    if (!_isPublic && !_partner) {
        NSLog(@"ERROR: No Conversation found.");
        [[ETRSessionManager sharedManager] endSession];
        [[self navigationController] popToRootViewControllerAnimated:YES];
        return NO;
    }
    
    // Make sure the room manager meets the requirements for this view controller.
    if (![ETRSessionManager sessionRoom] || ![[ETRSessionManager sharedManager] didBeginSession]) {
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
    [self scrollDownTableViewAnimated:YES];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    NSLog(@"DEBUG: didChangeObject atIndexPath:%@ forChangeType:%lu newIndexPath:%@", indexPath, (unsigned long)type, newIndexPath);
    
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
            NSLog(@"DEBUG: Updated message record: %ld, %ld, %@", [indexPath row], [newIndexPath row], anObject);
            break;
        }
        case NSFetchedResultsChangeMove: {
            [[self messagesTableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                            withRowAnimation:UITableViewRowAnimationFade];
            [[self messagesTableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                            withRowAnimation:UITableViewRowAnimationFade];
        }
    }
    [[self messagesTableView] reloadData];
    [self scrollDownTableViewAnimated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!_fetchedResultsController || ![[_fetchedResultsController fetchedObjects] count]) {
        return 0;
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
    
//    id<NSObject> record = [_fetchedResultsController objectAtIndexPath:indexPath];
//    if (!record || ![record isKindOfClass:[ETRAction class]]) {
//        NSLog(@"ERROR: Invalid record type at: %ld", [indexPath row]);
//        return [[UITableViewCell alloc] init];
//    }
    
    ETRAction *action = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    if ([action isSentAction]) {
        if ([action isPhotoMessage]) {
            ETRSentMediaCell * cell;
            cell = [tableView dequeueReusableCellWithIdentifier:ETRSentMediaCellIdentifier
                                                   forIndexPath:indexPath];
            [ETRImageLoader loadImageForObject:action
                                      intoView:[cell iconView]
                              placeHolderImage:[UIImage imageNamed:ETRImageNameImagePlaceholder]
                                   doLoadHiRes:NO];
            NSString *timestamp = [ETRReadabilityHelper formattedDate:[action sentDate]];
            [[cell timeLabel] setText:timestamp];
            return cell;
        } else {
            ETRSentMessageCell * cell;
            cell = [tableView dequeueReusableCellWithIdentifier:ETRSentMessageCellIdentifier
                                                   forIndexPath:indexPath];
            
            [[cell messageLabel] setText:[action messageContent]];
            NSString *timestamp = [ETRReadabilityHelper formattedDate:[action sentDate]];
            [[cell timeLabel] setText:timestamp];
            return cell;
        }
    } else {
        ETRUser * sender = [action sender];
        NSString * senderName;
        if (_isPublic) {
            if (sender && [sender name]) {
                senderName = [sender name];
            } else {
                senderName = @"x";
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
                [[cell nameLabel] removeFromSuperview];
            }
            [ETRImageLoader loadImageForObject:action
                                      intoView:[cell iconView]
                              placeHolderImage:[UIImage imageNamed:ETRImageNameImagePlaceholder]
                                   doLoadHiRes:NO];
            
            NSString *timestamp = [ETRReadabilityHelper formattedDate:[action sentDate]];
            [[cell timeLabel] setText:timestamp];
            return cell;
        } else {
            ETRReceivedMessageCell *cell;
            cell = [tableView dequeueReusableCellWithIdentifier:ETRReceivedMessageCellIdentifier
                                                   forIndexPath:indexPath];
            
//            [[[cell userIconView] layer] setCornerRadius:ETRIconViewCornerRadius];
//            [[cell userIconView] setClipsToBounds:YES];
            
            [ETRImageLoader loadImageForObject:[action sender]
                                      intoView:[cell userIconView]
                              placeHolderImage:[UIImage imageNamed:ETRImageNameUserIcon]
                                   doLoadHiRes:NO];
            if (_isPublic) {
                [[cell nameLabel] setText:senderName];
            } else {
                [[cell nameLabel] removeFromSuperview];
            }
            [[cell messageLabel] setText:[action messageContent]];
            NSString *timestamp = [ETRReadabilityHelper formattedDate:[action sentDate]];
            [[cell timeLabel] setText:timestamp];
            return cell;
        }
    }
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self hideMediaMenu];
}

// Scroll to the bottom of a table.
- (void)scrollDownTableViewAnimated:(BOOL)animated {
//    NSInteger bottomRow = [_messagesTableView numberOfRowsInSection:0] - 1;
//    if (bottomRow >= 0) {
//        NSIndexPath * indexPath = [NSIndexPath indexPathForRow:bottomRow inSection:0];
//        [[self messagesTableView] scrollToRowAtIndexPath:indexPath
//                                        atScrollPosition:UITableViewScrollPositionBottom
//                                                animated:animated];
//    }
}

#pragma mark - Alert Views

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
        CGPoint point = [gestureRecognizer locationInView:[self messagesTableView]];
        NSIndexPath * indexPath = [[self messagesTableView] indexPathForRowAtPoint:point];
        
        ETRAction * record = [_fetchedResultsController objectAtIndexPath:indexPath];
        _alertViewFactory = [[ETRAlertViewFactory alloc] init];
        [_alertViewFactory showMenuForMessage:record calledByViewController:self];
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

- (IBAction)mediaButtonPressed:(id)sender {
    // If the lower button, the camera button, is hidden, open the menu.
    
    if ([[self cameraButton] isHidden]) {
        if (![self updateConversationStatus]) {
            return;
        }
        
        // Expand the menu from the bottom.
        [ETRAnimator toggleBounceInView:[self cameraButton] completion:^{
            [ETRAnimator toggleBounceInView:[self galleryButton] completion:nil];
        }];
    } else {
        [self hideMediaMenu];
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
    [self dismissViewControllerAnimated:picker completion:nil];
    
    if (_isPublic) {
        [ETRCoreDataHelper dispatchPublicImageMessage:[ETRImageEditor imageFromPickerInfo:info]];
    } else if (_partner) {
        [ETRCoreDataHelper dispatchImageMessage:[ETRImageEditor imageFromPickerInfo:info]
                                    toRecipient:_partner];
    }
}

/*
 Closes the menu, if the upper button, the gallery button, is visible
*/
- (void)hideMediaMenu {
    [self updateConversationStatus];
    
    if(![[self galleryButton] isHidden]) {
        // Collapse the menu from the top.
        [ETRAnimator toggleBounceInView:[self galleryButton] completion:^{
            [ETRAnimator toggleBounceInView:[self cameraButton] completion:nil];
        }];
    }
}

- (IBAction)moreButtonPressed:(id)sender {
    // The More button is a Profile button in private chats.
    if (_isPublic) {
        [self performSegueWithIdentifier:ETRConversationToUserListSegue
                                  sender:nil];
    } else {
        [self performSegueWithIdentifier:ETRConversationToProfileSegue
                                  sender:_partner];
    }
}

- (void)exitButtonPressed:(id)sender {
    _alertViewFactory = [[ETRAlertViewFactory alloc] init];
    [_alertViewFactory showLeaveConfirmView];
}

#pragma mark - Keyboard Notifications

- (void)dismissKeyboard {
    [[self messageTextField] resignFirstResponder];
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
