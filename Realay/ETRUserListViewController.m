//
//  UserListViewController.m
//  Realay
//
//  Created by Michel on 29.09.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import "ETRUserListViewController.h"

#import "ETRChatViewController.h"
#import "ETRUser.h"
#import "ETRChat.h"
#import "ETRChatMessage.h"
#import "ETRViewProfileViewController.h"

#define kSegueToChat            @"userListToChatSegue"
#define kSegueToMap             @"userListToMapSegue"
#define kSegueToProfile         @"userListToViewProfileSegue"
#define kCellIdentifierConvo    @"conversationCell"
#define kCellIdentifierUser     @"userCell"
#define kCellIdentifierInfo     @"infoCell"

@implementation ETRUserListViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSInteger myControllerIndex;
    myControllerIndex = [[[self navigationController] viewControllers] count] - 1;
    [[ETRSession sharedSession] setUserListControllerIndex:myControllerIndex];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Navigation Bar:
    [self setTitle:[[[ETRSession sharedSession] room] title]];
    
    // Do not display empty cells at the end.
    [[self tableView] setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    [[self tableView] setDelegate:self];
    
    // Configure manual refresher.
    [[self refreshControl] addTarget:self action:@selector(updateUserList) forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

//    [[ETRSession sessionManager] setSessionDelegate:self];
    [[ETRSession sharedSession] setChatDelegate:self];
    [[ETRSession sharedSession] setUserListDelegate:self];
    
    [[self navigationController] setToolbarHidden:NO animated:YES];
    
    [[self tableView] reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[self navigationController] setToolbarHidden:NO animated:YES];
    
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
    
    NSInteger row = [indexPath row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifierInfo];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:kCellIdentifierInfo];
    };
    ETRUser *user;
    
    if ([indexPath section] == 0) {
        // Section 0 contains the conversations.
        
        if ([[[ETRSession sharedSession] sortedChatKeys] count] < 1) {
            // No conversation started yet.
            
            //TODO: Localization
            NSString *noConvos = @"No private conversations. Select a user to start one.";
            [[cell textLabel] setText:noConvos];
            [[cell textLabel] setAdjustsFontSizeToFitWidth:YES];
            
            // Do not do display any user-related views.
            return cell;
            
        } else {
            // Give me a regular conversation cell if we have at least one conversation open.
            
            // Get the chat for this cell from the array of chats through the array of sorted chats.
            NSString *chatKey = [[[ETRSession sharedSession] sortedChatKeys] objectAtIndex:row];
            ETRChat *chat = [[ETRSession sharedSession] chatForKey:chatKey];
            
            // Get the chat partner in this chat.
            NSString *userKey = [[chat partner] userKey];
            user = [[[ETRSession sharedSession] users] objectForKey:userKey];
            
            // Get the last message of this chat.
            NSInteger lastMsgIndex = [[chat messages] count] - 1;
            ETRChatMessage *lastMsg = [[chat messages] objectAtIndex:lastMsgIndex];
            [[cell detailTextLabel] setText:[lastMsg messageString]];
        }
    } else {
        // Section 1 contains the user cells.
        
        // Get the user for this cell from the user array through the array of sorted keys.
        NSArray *sortedUserKeys = [[ETRSession sharedSession] sortedUserKeys];
        NSString *userKey = [sortedUserKeys objectAtIndex:row];
        user = [[[ETRSession sharedSession] users] objectForKey:userKey];
        
        [[cell detailTextLabel] setText:[user status]];
    }
    
    
    [[cell textLabel] setText:[user name]];
    if (user.smallImage.size.height > 64) {
        [[cell imageView] setImage:[user smallImage]];
    } else {
        [[cell imageView] setImage:[UIImage imageNamed:@"empty.jpg"]];
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    switch (section) {
        case 0:     // Conversation section:
            if ([[[ETRSession sharedSession] sortedChatKeys] count] < 2) return 1;
            else return [[[ETRSession sharedSession] sortedChatKeys] count];
            break;
        case 1:     // User section
            return [[[ETRSession sharedSession] sortedUserKeys] count];
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
    
    ETRChat *selectedChat;
    NSInteger row = [indexPath row];
    
    if ([indexPath section] == 0) {
        NSArray *sortedChatKeys = [[ETRSession sharedSession] sortedChatKeys];
        if ([sortedChatKeys count] > 0) {
            NSString *rowChatKey = [sortedChatKeys objectAtIndex:row];
            selectedChat = [[ETRSession sharedSession] chatForKey:rowChatKey];
        }
    } else {
        NSArray *sortedUserKeys = [[ETRSession sharedSession] sortedUserKeys];
        NSString *userKey = [sortedUserKeys objectAtIndex:row];
        ETRUser *user = [[[ETRSession sharedSession] users] objectForKey:userKey];
        
        selectedChat = [ETRChat unknownIDChatWithPartner:user];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:kSegueToChat sender:selectedChat];
    
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
    
    if ([[segue identifier] isEqualToString:kSegueToChat]) {
        
        ETRChatViewController *destination = [segue destinationViewController];
        if ([sender isMemberOfClass:[ETRChat class]]) {
            [destination setChat:sender];
        }
        
    } else if([[segue identifier] isEqualToString:kSegueToProfile]) {
        // Just show my own user profile.
        
        ETRViewProfileViewController *destination = [segue destinationViewController];
        
        if ([sender isMemberOfClass:[ETRUser class]]) {
            ETRUser *user = (ETRUser *)sender;
            [destination setShowMyProfile:NO];
            [destination setUser:user];
        } else {
            [destination setShowMyProfile:YES];
        }
        
    }
}

@end
