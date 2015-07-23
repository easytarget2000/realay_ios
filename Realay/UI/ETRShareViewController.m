//
//  ETRShareViewController.m
//  Realay
//
//  Created by Michel on 22/07/15.
//  Copyright © 2015 Easy Target. All rights reserved.
//

#import "ETRShareViewController.h"

#import "ETRRoom.h"
#import "ETRSessionManager.h"
#import "ETRUIConstants.h"


@implementation ETRShareViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Reset Bar elements that might have been changed during navigation to other View Controllers.
    [[[self navigationController] navigationBar] setTranslucent:NO];
    [[self navigationController] setToolbarHidden:YES animated:YES];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (void)tableView:(nonnull UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString * shareTextFormat;
    switch ([indexPath row]) {
        case 1:
            shareTextFormat = @"Ich benutze die Realay App, um mit Leuten zu chatten, die auch bei %@ sind.";
            break;
            
        default:
            shareTextFormat = @"I am using the Realay app at %@ to chat with everyone around me.";
            break;
    }
    
    ETRRoom * sessionRoom = [ETRSessionManager sessionRoom];
    if (!sessionRoom) {
        [[self navigationController] popViewControllerAnimated:YES];
        return;
    }
    
    UIImage * shareImage = [sessionRoom lowResImage];

    NSString * shareText = [NSString stringWithFormat:shareTextFormat, [sessionRoom title], shareImage, nil];
    NSURL * shareURL = [NSURL URLWithString:@"http://realay.net"];

    NSArray * sharingItems = [NSArray arrayWithObjects:shareText, shareURL, nil];
    
    UIActivityViewController * activityController;
    activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems
                                                           applicationActivities:nil];
    [[activityController view] setTintColor:[ETRUIConstants primaryColor]];
    
    [self presentViewController:activityController animated:YES completion:^{
        [[self navigationController] popViewControllerAnimated:YES];
    }];
    
}

@end
