//
//  ETRIconDownloader.m
//  Realay
//
//  Created by Michel S on 11.03.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRIconDownloader.h"

#import "SharedMacros.h"

@implementation ETRIconDownloader {
    NSMutableData *_activeDlData;
    NSURLConnection *_imageConnection;
    ETRRoom *_room;
}

- (id)init {
    return nil;
}

- initWithRoom:(ETRRoom *)room {
    self = [super init];
    _room = room;
    return self;
}

- (void)startDownload {
    
    if (!_room) return;
    
    // Initialise empty data.
    _activeDlData = [NSMutableData data];

    // Prepare the URL to the download script.
    NSString *URLString = [NSString stringWithFormat:@"%@%@",
                           kURLPHPScripts, kPHPDownloadImage];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    // Prepare the POST request.
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    NSString *bodyString;
    bodyString = [NSString stringWithFormat:@"image_id=%ld", [_room imageID]];
    NSData *bodyData = [bodyString dataUsingEncoding:NSASCIIStringEncoding];
    [request setHTTPBody:[NSMutableData dataWithData:bodyData]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:kHTTPTimeout];
    
    NSURLConnection *newConnection;
    newConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    _imageConnection = newConnection;
}

- (void)cancelDownload {
    [_imageConnection cancel];
    _imageConnection = nil;
    _activeDlData = nil;
    _room = nil;
}

#pragma mark - NSURLConnectionDelegate
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_activeDlData appendData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // Release the data and clear the connection.
    _activeDlData = nil;
    _imageConnection = nil;
    NSLog(@"ERROR: %@", error);
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    if (!_room) return;
    
    // Try to build an image from the received data.
    UIImage *image = [[UIImage alloc] initWithData:_activeDlData];
    if (image) {
        [_room setSmallImage:image];
    } else {
        NSLog(@"ERROR: No image in data: %@", _activeDlData);
    }

    // Release the data and clear the connection.
    _activeDlData = nil;
    _imageConnection = nil;
    
    // Call delegate to signal ready icon.
    if (self.completionHandler) self.completionHandler();
}

@end
