//
//  UserListViewController.h
//  Realay
//
//  Created by Michel on 29.09.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ETRSession.h"

@interface ETRUserListViewController : UITableViewController <ETRChatDelegate, ETRUserListDelegate>

- (IBAction)mapButtonPressed:(id)sender;
- (IBAction)profileButtonPressed:(id)sender;

@end
