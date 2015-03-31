//
//  ChatViewController.h
//  Realay
//
//  Created by Michel S on 01.12.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ETRUser;

@interface ETRConversationViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView * messagesTableView;

@property (weak, nonatomic) IBOutlet UILabel *inputCover;

@property (weak, nonatomic) IBOutlet UIView *inputContainer;

@property (weak, nonatomic) IBOutlet UITextField * messageTextField;

//@property (weak, nonatomic) IBOutlet UIBarButtonItem * exitButton;

@property (weak, nonatomic) IBOutlet UIButton *mediaButton;

@property (weak, nonatomic) IBOutlet UIView *cameraButton;

@property (weak, nonatomic) IBOutlet UIView *galleryButton;

@property (weak, nonatomic) IBOutlet UIBarButtonItem * moreButton;

@property (strong, nonatomic) ETRUser * partner;

@property (nonatomic) BOOL isPublic;

- (IBAction)sendButtonPressed:(id)sender;

- (IBAction)mediaButtonPressed:(id)sender;

- (IBAction)galleryButtonPressed:(id)sender;

- (IBAction)cameraButtonPressed:(id)sender;

- (IBAction)moreButtonPressed:(id)sender;

@end

