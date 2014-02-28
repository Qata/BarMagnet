//
//  TorrentDownloaderModalWebViewController.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 1/03/2014.
//  Copyright (c) 2014 Carlo Tortorella. All rights reserved.
//

#import "TorrentDownloaderModalWebViewController.h"
#import "TorrentDownloaderWebViewController.h"

@implementation TorrentDownloaderModalWebViewController

- (id)initWithURL:(NSURL *)URL
{
	if ([super respondsToSelector:@selector(webViewController)])
	{
		self.webViewController = [TorrentDownloaderWebViewController.alloc initWithURL:URL];
		if (self = [super initWithRootViewController:self.webViewController]) {
			UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																						target:self.webViewController
																						action:@selector(doneButtonClicked:)];

			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
				self.webViewController.navigationItem.leftBarButtonItem = doneButton;
			else
				self.webViewController.navigationItem.rightBarButtonItem = doneButton;
		}
	}
    return self;
}

@end
