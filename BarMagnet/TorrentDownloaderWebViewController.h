//
//  TorrentDownloaderWebViewController.h
//  BarMagnet
//
//  Created by Carlo Tortorella on 1/03/2014.
//  Copyright (c) 2014 Carlo Tortorella. All rights reserved.
//

#import "SVWebViewController.h"

@interface SVWebViewController (WebViewDelegate)<UIWebViewDelegate>
@property (nonatomic, strong) UIWebView * webView;
@end

@interface TorrentDownloaderWebViewController : SVWebViewController<NSURLConnectionDataDelegate>
@property (nonatomic, strong) NSArray *adKeys;
@property (nonatomic, strong) NSMutableData * torrentData;
@property (nonatomic, strong) NSURL * torrentURL;
@end
