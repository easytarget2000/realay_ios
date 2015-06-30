//
//  ChatViewController.h
//  Realay
//
//  Created by Michel S on 01.12.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import "ETRBaseViewController.h"


@class ETRUser;


@interface ETRConversationViewController : ETRBaseViewController

@property (weak, nonatomic) IBOutlet UILabel *badgeLabel;

@property (weak, nonatomic) IBOutlet UITableView * messagesTableView;

@property (weak, nonatomic) IBOutlet UILabel * inputCover;

@property (weak, nonatomic) IBOutlet UITextView *messageInputView;

@property (weak, nonatomic) IBOutlet UIImageView * mediaButton;

@property (weak, nonatomic) IBOutlet UIView * cameraButton;

@property (weak, nonatomic) IBOutlet UIView * galleryButton;

@property (weak, nonatomic) IBOutlet UIBarButtonItem * moreButton;

@property (weak, nonatomic) IBOutlet UILabel * infoLabel;

@property (strong, nonatomic) ETRUser * partner;

@property (nonatomic) BOOL isPublic;

- (IBAction)sendButtonPressed:(id)sender;

- (IBAction)mediaButtonPressed:(id)sender;

- (IBAction)galleryButtonPressed:(id)sender;

- (IBAction)cameraButtonPressed:(id)sender;

- (IBAction)moreButtonPressed:(id)sender;

- (IBAction)receivedMediaPressed:(id)sender;

- (IBAction)sentMediaPressed:(id)sender;

@end

