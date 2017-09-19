//
//  TorrentDownloaderModalWebViewController.h
//  BarMagnet
//
//  Created by Charlotte Tortorella on 1/03/2014.
//  Copyright (c) 2014 Charlotte Tortorella. All rights reserved.
//

#import "SVModalWebViewController.h"
#import "SVWebViewController.h"

@interface SVModalWebViewController (WebViewController)
@property (nonatomic, strong) SVWebViewController * webViewController;
@end

@interface TorrentDownloaderModalWebViewController : SVModalWebViewController

@end
