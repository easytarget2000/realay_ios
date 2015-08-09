//
//  ETRProfileSocialCell.m
//  Realay
//
//  Created by Michel on 06/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRProfileSocialCell.h"

#import "ETRUIConstants.h"
#import "ETRUser.h"
#import "ETRAnimator.h"


static NSString *const ETRImageFacebook = @"Facebook";

static NSString *const ETRImageInstagram = @"Instagram";

static NSString *const ETRImageTwitter = @"Twitter";


@interface ETRProfileSocialCell ()

@property (strong, nonatomic) ETRUser * user;

@property (nonatomic) ETRSocialNetwork network;

@end


@implementation ETRProfileSocialCell

- (void)setUpForUser:(ETRUser *)user network:(ETRSocialNetwork)network{
    _user = user;
    _network = network;
    
    if (_network == ETRSocialNetworkFacebook && [[_user facebook] length]) {
        [[self iconView] setImage:[UIImage imageNamed:ETRImageFacebook]];
        [[self nameLabel] setText:[_user facebook]];
    } else if (_network == ETRSocialNetworkInstagram && [[_user instagram] length]) {
        [[self iconView] setImage:[UIImage imageNamed:ETRImageInstagram]];
        NSString * instagramName;
        if ([[_user instagram] characterAtIndex:0] != '@') {
            instagramName= [NSString stringWithFormat:@"@%@", [_user instagram]];
        } else {
            instagramName = [_user instagram];
        }
        [[self nameLabel] setText:instagramName];
    } else if (_network == ETRSocialNetworkTwitter && [[user twitter] length]) {
        [[self iconView] setImage:[UIImage imageNamed:ETRImageTwitter]];
        NSString * twitterName;
        if ([[_user twitter] characterAtIndex:0] != '@') {
            twitterName = [NSString stringWithFormat:@"@%@", [_user twitter]];
        } else {
            twitterName = [_user twitter];
        }
        [[self nameLabel] setText:twitterName];
    } else {
        [[self iconView] removeFromSuperview];
        [[self nameLabel] removeFromSuperview];
    }
    
}

- (void)openProfile {
    switch (_network) {
        case ETRSocialNetworkFacebook: {
            NSString * fbSearchURL;
            fbSearchURL = [NSString stringWithFormat:@"https://facebook.com/search/results/?q=%@", [_user facebook]];
            fbSearchURL = [fbSearchURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbSearchURL]];
            return;
        }
            
        case ETRSocialNetworkInstagram: {
            NSString * instagramName;
            NSInteger startIndex;
            for (startIndex = 0; startIndex < [[_user instagram] length]; startIndex++) {
                if ([[_user instagram] characterAtIndex:startIndex] != '@') {
                    break;
                }
            }
            instagramName = [[_user instagram] substringFromIndex:startIndex];
            NSString * fallbackURL;
            fallbackURL = [NSString stringWithFormat:@"http://instagram.com/_u/%@", instagramName];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fallbackURL]];
            return;
        }
            
        case ETRSocialNetworkTwitter: {
            NSString * twitterName;
            NSInteger startIndex;
            for (startIndex = 0; startIndex < [[_user twitter] length]; startIndex++) {
                if ([[_user twitter] characterAtIndex:startIndex] != '@') {
                    break;
                }
            }
            twitterName = [[_user twitter] substringFromIndex:startIndex];
            
            NSString * profileURL = [NSString stringWithFormat:@"twitter:///user?%@", twitterName];
            NSURL * twitterURL = [NSURL URLWithString:profileURL];
            if ([[UIApplication sharedApplication] canOpenURL:twitterURL]) {
                [[UIApplication sharedApplication] openURL:twitterURL];
            } else {
                NSString * fallbackURL;
                fallbackURL = [NSString stringWithFormat:@"https://twitter.com/%@", [_user twitter]];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fallbackURL]];
            }
        }
    }
}

//- (IBAction)facebookButtonPressed:(id)sender {
//    [ETRAnimator flashFadeView:sender completion:^{
//        if (!_user || ![_user facebook]) {
//            return;
//        }
//        
//        NSString * profileURL = [NSString stringWithFormat:@"fb:///profile/%@", [_user facebook]];
//        NSURL * facebookURL = [NSURL URLWithString:profileURL];
//        if ([[UIApplication sharedApplication] canOpenURL:facebookURL]) {
//            [[UIApplication sharedApplication] openURL:facebookURL];
//        } else {
//            NSString * fallbackURL;
//            fallbackURL = [NSString stringWithFormat:@"https://facebook.com/%@", [_user facebook]];
//            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fallbackURL]];
//        }
//    }];
//}

- (void)prepareForReuse {
    [self layoutSubviews];
}

@end
