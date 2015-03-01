//
//  ChatViewController.h
//  Realay
//
//  Created by Michel S on 01.12.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ETRSession.h"

@interface ETRChatViewController : UIViewController
    <UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView        *messagesTableView;
@property (weak, nonatomic) IBOutlet UITextField        *messageTextField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem    *leaveButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem    *moreButton;

@property (nonatomic) long conversationID;

- (IBAction)sendButtonPressed:(id)sender;
- (IBAction)leaveButtonPressed:(id)sender;
- (IBAction)moreButtonPressed:(id)sender;

@end

