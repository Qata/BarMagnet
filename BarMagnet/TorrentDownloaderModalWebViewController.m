//
//  TorrentDownloaderModalWebViewController.m
//  BarMagnet
//
//  Created by Charlotte Tortorella on 1/03/2014.
//  Copyright (c) 2014 Charlotte Tortorella. All rights reserved.
//

#import "TorrentDownloaderModalWebViewController.h"
#import "TorrentDownloaderWebViewController.h"

@implementation TorrentDownloaderModalWebViewController

- (instancetype)initWithURLRequest:(NSURLRequest *)request {
	self.webViewController = [[TorrentDownloaderWebViewController alloc] initWithURLRequest:request];
	if (self = [super initWithRootViewController:self.webViewController]) {
		UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																					target:self.webViewController
																					action:@selector(doneButtonTapped:)];

		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			self.webViewController.navigationItem.leftBarButtonItem = doneButton;
		else
			self.webViewController.navigationItem.rightBarButtonItem = doneButton;
	}
	return self;
}

@end
