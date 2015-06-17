//
//  ETRUserListBaseViewController.h
//  Realay
//
//  Created by Michel on 27/05/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRBaseViewController.h"

#import "ETRCoreDataHelper.h"


@interface ETRUserListBaseViewController : ETRBaseViewController
<UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic) BOOL doShowConversations;

@property (strong, nonatomic) NSFetchedResultsController * resultsController;

- (void)setUpForConversationList:(BOOL)doShowConversations;

@end
