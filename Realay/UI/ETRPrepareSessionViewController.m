//
//  ETRPrepareSessionViewController.m
//  Realay
//
//  Created by Michel on 07/07/15.
//  Copyright © 2015 Easy Target. All rights reserved.
//

#import "ETRPrepareSessionViewController.h"

#import "ETRAlertViewFactory.h"
#import "ETRFormatter.h"
#import "ETRLocationManager.h"
#import "ETRRoom.h"
#import "ETRSessionManager.h"

@implementation ETRPrepareSessionViewController

- (void)joinButtonPressed:(id)sender joinSegue:(NSString *)joinSegue {
    // Only perform a join action, if the user did not join yet.
    if ([[ETRSessionManager sharedManager] didStartSession]) {
        return;
    }
    
    ETRRoom * preparedRoom = [ETRSessionManager sessionRoom];
    NSDate * startDate = [preparedRoom startDate];
    if (startDate) {
        NSTimeInterval intervalUntilOpening = [startDate timeIntervalSinceNow];
        if (intervalUntilOpening > 0) {
            NSString * messageFormat = NSLocalizedString(@"Starts_at", @"%@ starts at %@");
            NSString * formattedDate = [ETRFormatter formattedDate:startDate];
            NSString * message = [NSString stringWithFormat:messageFormat, [preparedRoom title], formattedDate];
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Not_Yet", @"Please Wait")
                                        message:message
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", @"Understood")
                              otherButtonTitles:nil] show];
            return;
        }
    }
    
    // Update the current location.
    [[ETRLocationManager sharedManager] launch:nil];
    
#ifdef DEBUG_JOIN
    [self performSegueWithIdentifier:ETRSegueMapToPassword sender:nil];
#else
    if (![ETRLocationManager didAuthorizeWhenInUse]) {
        // The location access has not been authorized.
        
        [[self alertHelper] showSettingsAlertBeforeJoin];
        LastSettingsAlert = CFAbsoluteTimeGetCurrent();
        
    } else if ([ETRLocationManager isInSessionRegion]) {
        // Show the password prompt, if the device location is inside the region.
        [self performSegueWithIdentifier:joinSegue sender:self];
    } else {
        // The user is outside of the radius.
        [ETRAlertViewFactory showRoomDistanceAlert];
    }
#endif
}

@end
