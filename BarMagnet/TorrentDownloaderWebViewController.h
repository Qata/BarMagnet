//
//  TorrentDownloaderWebViewController.h
//  BarMagnet
//
//  Created by Charlotte Tortorella on 1/03/2014.
//  Copyright (c) 2014 Charlotte Tortorella. All rights reserved.
//

#import "SVWebViewController.h"

@interface SVWebViewController (WebViewDelegate)<UIWebViewDelegate>
@property (nonatomic, strong) UIWebView * webView;
@end

@interface TorrentDownloaderWebViewController : SVWebViewController<NSURLConnectionDataDelegate>
@property (nonatomic, strong) NSArray *adKeys;
@property (nonatomic, strong) NSMutableDictionary * torrents;
@end
