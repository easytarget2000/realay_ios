//
//  ETRProfileSocialCell.m
//  Realay
//
//  Created by Michel on 06/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRProfileSocialCell.h"

#import "ETRUser.h"
#import "ETRAnimator.h"


@interface ETRProfileSocialCell ()

@property (strong, nonatomic) ETRUser * user;

@end

@implementation ETRProfileSocialCell

- (void)setUpForUser:(ETRUser *)user {
    if (!user) {
        return;
    }
    
    _user = user;
        
    if (![_user facebook] || ![[_user facebook] length]) {
        [[self facebookButton] removeFromSuperview];
    }
    
    if (![_user instagram] || ![[_user instagram] length]) {
        [[self instagramButton] removeFromSuperview];
    }
    
    if (![_user twitter] || ![[_user twitter] length]) {
        [[self twitterButton] removeFromSuperview];
    }
}

- (IBAction)facebookButtonPressed:(id)sender {
    [ETRAnimator flashFadeView:sender completion:^{
        if (!_user || ![_user facebook]) {
            return;
        }
        
        NSString * profileURL = [NSString stringWithFormat:@"fb:///profile/%@", [_user facebook]];
        NSURL * facebookURL = [NSURL URLWithString:profileURL];
        if ([[UIApplication sharedApplication] canOpenURL:facebookURL]) {
            [[UIApplication sharedApplication] openURL:facebookURL];
        } else {
            NSString * fallbackURL;
            fallbackURL = [NSString stringWithFormat:@"https://facebook.com/%@", [_user facebook]];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fallbackURL]];
        }
    }];
}

- (IBAction)instagramButtonPressed:(id)sender {
    [ETRAnimator flashFadeView:sender completion:^{
        if (!_user || ![_user instagram]) {
            return;
        }
        
        NSString * fallbackURL;
        fallbackURL = [NSString stringWithFormat:@"http://instagram.com/_u/%@", [_user instagram]];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fallbackURL]];
    }];
}

- (IBAction)twitterButtonPressed:(id)sender {
    [ETRAnimator flashFadeView:sender completion:^{
        if (!_user || ![_user twitter]) {
            return;
        }
        
        NSString * profileURL = [NSString stringWithFormat:@"twitter:///user?%@", [_user twitter]];
        NSURL * twitterURL = [NSURL URLWithString:profileURL];
        if ([[UIApplication sharedApplication] canOpenURL:twitterURL]) {
            [[UIApplication sharedApplication] openURL:twitterURL];
        } else {
            NSString * fallbackURL;
            fallbackURL = [NSString stringWithFormat:@"https://twitter.com/%@", [_user twitter]];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fallbackURL]];
        }
    }];
}

- (void)prepareForReuse {
    [self layoutSubviews];
}

@end
