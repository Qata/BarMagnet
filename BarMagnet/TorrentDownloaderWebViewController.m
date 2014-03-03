//
//  TorrentDownloaderWebViewController.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 1/03/2014.
//  Copyright (c) 2014 Carlo Tortorella. All rights reserved.
//

#import "TorrentDownloaderWebViewController.h"
#import "TorrentDelegate.h"
#import "TorrentClient.h"

@implementation TorrentDownloaderWebViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	[TorrentDelegate.sharedInstance.currentlySelectedClient showNotification:self.navigationController];
	self.torrentData = NSMutableData.new;
	self.adKeys = [NSDictionary dictionaryWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"AdBlocker" ofType:@"plist"]][@"ads"];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	if ([response.MIMEType isEqualToString:@"application/x-bittorrent"])
	{
		self.torrentURL = response.URL;
	}
	else
	{
		[connection cancel];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[self.torrentData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[TorrentDelegate.sharedInstance.currentlySelectedClient handleTorrentData:self.torrentData withURL:self.torrentURL];
	self.torrentData = NSMutableData.new;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSLog(@"%@", request.URL.absoluteString);
	for (NSString * key in self.adKeys)
	{
		if ([request.URL.absoluteString rangeOfString:key].location != NSNotFound)
		{
			return NO;
		}
	}

	if (request.URL.absoluteString.length > 7 && [[request.URL.absoluteString substringToIndex:7] isEqual:@"magnet:"])
	{
		[TorrentDelegate.sharedInstance.currentlySelectedClient handleMagnetLink:request.URL.absoluteString];
		return NO;
	}
	else if (request.URL.absoluteString.length > 8 && [[request.URL.absoluteString substringFromIndex:request.URL.absoluteString.length - 8] isEqual:@".torrent"])
	{
		[TorrentDelegate.sharedInstance.currentlySelectedClient handleTorrentURL:request.URL];
		return NO;
	}
	else
	{
		[NSURLConnection connectionWithRequest:request delegate:self];
	}
	return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	if ([super respondsToSelector:@selector(webViewDidFinishLoad:)])
	{
		[super webViewDidFinishLoad:webView];
	}
	UILabel * titleView = [UILabel.alloc initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
	titleView.backgroundColor = UIColor.clearColor;
	titleView.textAlignment = NSTextAlignmentCenter;
	if ([[UIDevice.currentDevice.systemVersion componentsSeparatedByString:@"."].firstObject integerValue] < 7)
	{
		titleView.textColor = [UIColor whiteColor];
	}
	titleView.text = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
	titleView.userInteractionEnabled = YES;
	[titleView addGestureRecognizer:[UITapGestureRecognizer.alloc initWithTarget:self action:@selector(showPageAddress)]];
	self.navigationItem.titleView = titleView;
}

- (void)showPageAddress
{
	if ([super respondsToSelector:@selector(webView)])
	{
		[[UIAlertView.alloc initWithTitle:self.webView.request.URL.absoluteString message:nil delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
	}
}

@end
