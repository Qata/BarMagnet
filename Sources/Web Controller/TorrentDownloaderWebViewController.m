//
//  TorrentDownloaderWebViewController.m
//  BarMagnet
//
//  Created by Charlotte Tortorella on 1/03/2014.
//  Copyright (c) 2014 Charlotte Tortorella. All rights reserved.
//

#import "TorrentDownloaderWebViewController.h"
#import "TorrentClient.h"
#import "TorrentDelegate.h"

@implementation TorrentDownloaderWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [NSHTTPCookieStorage sharedHTTPCookieStorage].cookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;
    [TorrentDelegate.sharedInstance.currentlySelectedClient showNotification:self.navigationController];
    self.torrents = NSMutableDictionary.new;
    self.adKeys = [NSDictionary dictionaryWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"AdBlocker" ofType:@"plist"]][@"ads"];
    self.webView.dataDetectorTypes = UIDataDetectorTypeNone;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([response.MIMEType isEqualToString:@"application/x-bittorrent"]) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [self.torrents setObject:@[ NSMutableData.new, response.URL ] forKey:connection.description];
    } else {
        [connection cancel];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [[[self.torrents objectForKey:connection.description] firstObject] appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [TorrentDelegate.sharedInstance.currentlySelectedClient handleTorrentData:[[self.torrents objectForKey:connection.description] firstObject]
                                                                      withURL:[[self.torrents objectForKey:connection.description] lastObject]];
    [self.torrents removeObjectForKey:connection.description];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    for (NSString *key in self.adKeys) {
        if ([request.URL.absoluteString containsString:key]) {
            printf("Blocking: %s\n", request.URL.absoluteString.UTF8String);
            return NO;
        }
    }
    printf("Accepting: %s\n", request.URL.absoluteString.UTF8String);

    if ([request.URL.lastPathComponent hasSuffix:@".torrent"]) {}
    
    if ([request.URL.scheme isEqual:@"magnet"]) {
        [TorrentDelegate.sharedInstance.currentlySelectedClient handleMagnetLink:request.URL.absoluteString];
        return NO;
    } else if ([request.URL.lastPathComponent hasSuffix:@".torrent"]) {
        [TorrentDelegate.sharedInstance.currentlySelectedClient handleTorrentURL:request.URL];
        return NO;
    } else {
        [NSURLConnection connectionWithRequest:request delegate:self];
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if ([super respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [super webViewDidFinishLoad:webView];
    }
    UILabel *titleView = [UILabel.alloc initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    titleView.backgroundColor = UIColor.clearColor;
    titleView.textAlignment = NSTextAlignmentCenter;
    if ([[UIDevice.currentDevice.systemVersion componentsSeparatedByString:@"."].firstObject integerValue] < 7) {
        titleView.textColor = [UIColor whiteColor];
    }
    titleView.text = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    titleView.userInteractionEnabled = YES;
    [titleView addGestureRecognizer:[UITapGestureRecognizer.alloc initWithTarget:self action:@selector(showPageAddress)]];
    self.navigationItem.titleView = titleView;
}

- (void)showPageAddress {
    if ([super respondsToSelector:@selector(webView)]) {
        [[UIAlertView.alloc initWithTitle:self.webView.request.URL.absoluteString
                                  message:nil
                                 delegate:self
                        cancelButtonTitle:@"Close"
                        otherButtonTitles:@"Copy", nil] show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        UIPasteboard *appPasteboard = [UIPasteboard generalPasteboard];
        appPasteboard.persistent = YES;
        appPasteboard.string = self.webView.request.URL.absoluteString;
    }
}

@end
