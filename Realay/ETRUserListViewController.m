//
//  UserListViewController.m
//  Realay
//
//  Created by Michel on 29.09.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import "ETRUserListViewController.h"

#import "ETRAction.h"
#import "ETRConversation.h"
#import "ETRConversationViewController.h"
#import "ETRDetailsViewController.h"
#import "ETRImageLoader.h"
#import "ETRRoom.h"
#import "ETRSession.h"
#import "ETRUser.h"

#define kSegueToConversation        @"userListToConversationSegue"
#define kSegueToMap                 @"userListToMapSegue"
#define kSegueToProfile             @"userListToViewProfileSegue"
#define kCellIdentifierConvo        @"conversationCell"
#define kCellIdentifierUser         @"userCell"
#define kCellIdentifierInfo         @"infoCell"

@implementation ETRUserListViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSInteger myControllerIndex;
    myControllerIndex = [[[self navigationController] viewControllers] count] - 1;
    [[ETRSession sharedManager] setUserListControllerIndex:myControllerIndex];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Navigation Bar:
    [self setTitle:[[ETRSession sessionRoom] title]];
    
    // Do not display empty cells at the end.
    [[self tableView] setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    [[self tableView] setDelegate:self];
    
    // Configure manual refresher.
    [[self refreshControl] addTarget:self action:@selector(updateUserList) forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[self navigationController] setToolbarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[self tableView] reloadData];
    [[self refreshControl] endRefreshing];
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"WARNING: ETRUserListViewController DEALLOC");
#endif
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    NSInteger row = [indexPath row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifierInfo];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:kCellIdentifierInfo];
    };
    ETRUser *user;
    
    if ([indexPath section] == 0) {
        // Section 0 contains the conversations.
        
        if ([[[ETRSession sharedManager] sortedChatKeys] count] < 1) {
            // No conversation started yet.
            
            NSString *noConvos = NSLocalizedString(@"No_private_conversations", @"No PMs yet");
            [[cell textLabel] setText:noConvos];
            [[cell textLabel] setAdjustsFontSizeToFitWidth:YES];
            
            // Do not do display any user-related views.
            return cell;
            
        } else {
            // Give me a regular conversation cell if we have at least one conversation open.
            
        }
    } else {
        // Section 1 contains the user cells.
        
    }
    
    
    [[cell textLabel] setText:[user name]];
    [ETRImageLoader loadImageForObject:user intoView:[cell imageView] doLoadHiRes:NO];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    switch (section) {
        case 0:     // Conversation section:
            if ([[[ETRSession sharedManager] sortedChatKeys] count] < 2) return 1;
            else return [[[ETRSession sharedManager] sortedChatKeys] count];
            break;
        case 1:     // User section
            return [[[ETRSession sharedManager] sortedUserKeys] count];
        default:
            return 0;
            break;
    }
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    //TODO: Localization
    NSString *convHeader = @"Private Conversations";
    NSString *usersHeader = @"Users";
    
    switch (section) {
        case 0:
            if ([tableView numberOfSections] == 1) return usersHeader;
            else return convHeader;
            break;
        case 1:
            return usersHeader;
        default:
            return @"";
            break;
    }
}

#pragma mark - ETRChatViewControllerDelegate

- (void)chatDidUpdateWithKey:(NSString *)chatKey {
    [[self tableView] reloadData];
}

#pragma mark - ETRUserListDelegate

- (void)didUpdateUserChatList {
    [[self tableView] reloadData];
}

#pragma mark - Navigation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ETRConversation *selectedConversation;
    [self performSegueWithIdentifier:kSegueToConversation sender:selectedConversation];
}

- (IBAction)mapButtonPressed:(id)sender {
//    NSInteger mapControllerIndex = [[ETRManager sharedManager] mapControllerIndex];
//    UINavigationController *navc = [self navigationController];
//    UIViewController *mapController = [[navc viewControllers] objectAtIndex:mapControllerIndex];
//    
//    if (mapController) {
////        [navc popToViewController:mapController animated:YES];
//
//    } else {
//        NSLog(@"ERROR: No map view controller on stack.");
//    }
    
    [self performSegueWithIdentifier:kSegueToMap sender:self];
}

- (IBAction)profileButtonPressed:(id)sender {
    [self performSegueWithIdentifier:kSegueToProfile sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    id destination = [segue destinationViewController];
    
    if ([destination isKindOfClass:[ETRConversationViewController class]]) {
        if ([sender isKindOfClass:[ETRUser class]]) {
            ETRConversationViewController *conversation;
            conversation = (ETRConversationViewController *)destination;
            [conversation setPartner:(ETRUser *)sender];
        }
    }
}

@end
