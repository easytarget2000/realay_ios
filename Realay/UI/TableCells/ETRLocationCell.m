//
//  ETRLocationCell.m
//  Realay
//
//  Created by Michel on 13/07/15.
//  Copyright © 2015 Easy Target. All rights reserved.
//

#import "ETRLocationCell.h"

#import "ETRBouncer.h"
#import "ETRLocationManager.h"
#import "ETRRoom.h"
#import "ETRSessionManager.h"

@implementation ETRLocationCell

- (void)awakeFromNib {
    NSString * firstLine;
    if ([ETRLocationManager isInSessionRegion]) {
        firstLine = NSLocalizedString(@"Currently_here", @"Correct location");
    } else {
        NSString * distanceFormat = NSLocalizedString(@"Current_distance", @"%d m away");
        NSNumber * distance = [[ETRSessionManager sessionRoom] distance];
        firstLine = [NSString stringWithFormat:distanceFormat, distance];
    }
    
    BOOL didStartSession = [[ETRSessionManager sharedManager] didStartSession];
    
    NSString * secondLine;
    if (didStartSession) {
        // The Location Kick Time may be nil if there haven't been any warnings.
        secondLine = [[ETRBouncer sharedManager] locationKickTime];
    } else {
        secondLine = NSLocalizedString(@"Ask_someone", @"Password explanation");
    }
    
    if (secondLine) {
        [[self label] setText:[NSString stringWithFormat:@"%@\n%@", firstLine, secondLine]];
    } else {
        [[self label] setText:firstLine];
    }
}

- (IBAction)shareButtonPressed:(id)sender {
    
}

@end
