//
//  ETRProfileHeaderEditorCell.m
//  Realay
//
//  Created by Michel on 07/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRProfileHeaderEditorCell.h"

#import "ETRUser.h"

@implementation ETRProfileHeaderEditorCell

- (void)setUpWithTag:(NSInteger)tag forUser:(id)user{
    if (!user) {
        return;
    }
    
    [[self nameField] setTag:tag];
    [[self nameField] setText:[user name]];
}

@end
