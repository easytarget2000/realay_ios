//
//  ETRUserListBaseViewController.m
//  Realay
//
//  Created by Michel on 27/05/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRUserListBaseViewController.h"

#import "ETRAction.h"
#import "ETRAnimator.h"
#import "ETRConversation.h"
#import "ETRConversationViewController.h"
#import "ETRImageEditor.h"
#import "ETRImageLoader.h"
#import "ETRImageView.h"
#import "ETRFormatter.h"
#import "ETRSessionTabBarController.h"
#import "ETRUIConstants.h"
#import "ETRUser.h"
#import "ETRUserCell.h"


@interface ETRUserListBaseViewController ()

@property (nonatomic) BOOL doShowInfoView;

@property (weak, nonatomic) IBOutlet UITableView * tableView;

@end


@implementation ETRUserListBaseViewController

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // The User list has a fixed row height.
    [[self tableView] setRowHeight:ETRRowHeightUser];
    
    NSString * backButtonTitle = NSLocalizedString(@"Users", @"List of Users");
    [[[self navigationItem] backBarButtonItem] setTitle:backButtonTitle];
}

- (void)setUpForConversationList:(BOOL)doShowConversations {
    
    _doShowConversations = doShowConversations;
    _doShowInfoView = NO;
    
    // Enable the Fetched Results Controllers.
    if (_doShowConversations) {
        _resultsController = [ETRCoreDataHelper conversationResulsControllerWithDelegate:self];
    } else {
        _resultsController = [ETRCoreDataHelper userListResultsControllerWithDelegate:self];
    }
    
    NSError * error = nil;
    [_resultsController performFetch:&error];
    if (error) {
        NSLog(@"ERROR: %@: performFetch: %@", [self class], error);
    }
    
    //    // Do not display empty cells at the end.
    //    [[self usersTableView] setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[self tableView] reloadData];
    
    // Load any remaining images after a while, if the table is calm.
    dispatch_after(
                   dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                   dispatch_get_main_queue(),
                   ^{
                       if (![[self tableView] isDragging] && ![[self tableView] isDecelerating]) {
                           [self loadImagesForOnScreenRows];
                       }
                   }
                   );
}

#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [[self tableView] beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [[self tableView] endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [[self tableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                         withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
            
        case NSFetchedResultsChangeDelete: {
            [[self tableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                         withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
            
        case NSFetchedResultsChangeUpdate: {
            UITableViewCell * cell = [[self tableView] cellForRowAtIndexPath:indexPath];
            if (!cell || ![cell isKindOfClass:[ETRUserCell class]]) {
                NSLog(@"ERROR: %@: Could not update cell at Index Path %@", [self class], indexPath);
            } else {
                [self configureUserCell:(ETRUserCell *)cell atIndexPath:indexPath];
            }
            break;
        }
            
        case NSFetchedResultsChangeMove: {
            [[self tableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                         withRowAnimation:UITableViewRowAnimationFade];
            [[self tableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                         withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}



#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows;
    if (!_resultsController) {
        numberOfRows = 0;
    } else {
        numberOfRows = [[_resultsController fetchedObjects] count];
    }
    
    _doShowInfoView = numberOfRows < 1;
    
    if (_doShowInfoView) {
        // Wait for possible results before actually deciding to show the Info View.
        dispatch_after(
                       dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                       dispatch_get_main_queue(),
                       ^{
                           [ETRAnimator fadeView:[self infoView]
                                        doAppear:_doShowInfoView
                                      completion:nil];
                       });
    } else {
        // Hiding the Info View happens immediately.
        [ETRAnimator fadeView:[self infoView] doAppear:NO completion:nil];
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ETRUserCell * userCell = [tableView dequeueReusableCellWithIdentifier:ETRCellIdentifierUser
                                                             forIndexPath:indexPath];
    [self configureUserCell:userCell atIndexPath:indexPath];
    return userCell;
}

- (void)configureUserCell:(ETRUserCell *)cell atIndexPath:(NSIndexPath *)indexPath {

    ETRUser * user;
    if (_doShowConversations) {
        ETRConversation * convo = [_resultsController objectAtIndexPath:indexPath];
        user = [convo partner];
        
        ETRAction * lastMessage = [convo lastMessage];
        
        if ([lastMessage isPhotoMessage]) {
            [[cell infoLabel] setText:NSLocalizedString(@"Picture", @"Picture")];
        } else {
            [[cell infoLabel] setText:[lastMessage messageContent]];
        }
        
        NSString * timeStamp = [ETRFormatter formattedDate:[lastMessage sentDate]];
        [[cell timeLabel] setText:timeStamp];
        
        if ([[convo hasUnreadMessage] boolValue]) {
            [[cell infoLabel] setTextColor:[ETRUIConstants accentColor]];
            [[cell infoLabel] setFont:[UIFont boldSystemFontOfSize:ETRFontSizeSmall]];
        } else {
            [[cell infoLabel] setTextColor:[ETRUIConstants primaryColor]];
            [[cell infoLabel] setFont:[UIFont systemFontOfSize:ETRFontSizeSmall]];
        }
        
    } else {
        // The Index Path gives Section 1 but the Fetched Results Controller assumes its values are in Section 0.
        NSIndexPath * alignedPath = [NSIndexPath indexPathForRow:[indexPath row] inSection:0];
        user = [_resultsController objectAtIndexPath:alignedPath];
        [[cell infoLabel] setText:[user status]];
    }
    
    [[cell nameLabel] setText:[user name]];
    
    if (![[self tableView] isDragging] && ![[self tableView] isDecelerating]) {
        [ETRImageLoader loadImageForObject:user
                                  intoView:[cell iconView]
                          placeHolderImage:nil
                               doLoadHiRes:YES];
    } else {
        if ([user lowResImage]) {
            [ETRImageEditor cropImage:[user lowResImage]
                            imageName:[user imageFileName:NO]
                          applyToView:[cell iconView]];
        } else {
            [[cell iconView] setImage:[UIImage imageNamed:ETRImageNameUserIcon]];
        }
    }
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Hides the selection and if a valid selection was made,
    // opens a Conversation View Controller with the selected partner User.
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    
    ETRUser * selectedUser;
    if (_doShowConversations) {
        ETRConversation * record = [_resultsController objectAtIndexPath:indexPath];
        selectedUser = [record partner];
    } else {
        selectedUser = [_resultsController objectAtIndexPath:indexPath];
    }
    
    UIStoryboard * storyboard = [self storyboard];

    ETRConversationViewController * conversationViewController;
    conversationViewController = [storyboard instantiateViewControllerWithIdentifier:ETRViewControllerIDConversation];
    
    [conversationViewController setPartner:selectedUser];
    [[self navigationController] pushViewController:conversationViewController
                                           animated:YES];
}

#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self loadImagesForOnScreenRows];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                 willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self loadImagesForOnScreenRows];
    }
}

- (void)loadImagesForOnScreenRows {
    if ([[self tableView] numberOfRowsInSection:0] > 0) {
        
        
        NSArray * visiblePaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath * indexPath in visiblePaths) {
            ETRUserCell * cell;
            cell = (ETRUserCell *)[[self tableView] cellForRowAtIndexPath:indexPath];
            
            
            [ETRImageLoader loadImageForObject:[_resultsController objectAtIndexPath:indexPath]
                                      intoView:[cell iconView]
                              placeHolderImage:nil
                                   doLoadHiRes:YES];
        }
    }
}

@end
