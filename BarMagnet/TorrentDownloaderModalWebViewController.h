//
//  TorrentDownloaderModalWebViewController.h
//  BarMagnet
//
//  Created by Carlo Tortorella on 1/03/2014.
//  Copyright (c) 2014 Carlo Tortorella. All rights reserved.
//

#import "SVModalWebViewController.h"
#import "SVWebViewController.h"

@interface SVModalWebViewController (WebViewController)
@property (nonatomic, strong) SVWebViewController * webViewController;
@end

@interface TorrentDownloaderModalWebViewController : SVModalWebViewController

@end
