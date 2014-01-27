//
//  AddTorrentViewController.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 15/07/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

@import AVFoundation;

#import "AddTorrentViewController.h"
#import "TorrentDelegate.h"
#import "FileHandler.h"
#import "TorrentClient.h"
#import "SVWebViewController.h"

@interface AddTorrentViewController () 
@end

@implementation AddTorrentViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	[self setTitle:@"Add Torrent"];
	[self.textBox becomeFirstResponder];
	if ([[UIDevice.currentDevice.systemVersion componentsSeparatedByString:@"."].firstObject integerValue] < 7)
	{
		[self.scanQRCodeButton setHidden:YES];
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	NSString * text = [[self textBox] text];
	if ([text length])
	{
		NSString * magnet = @"magnet:";
		if (text.length > magnet.length && [[text substringWithRange:NSMakeRange(0, magnet.length)] isEqual:magnet])
		{
			[[TorrentDelegate sharedInstance] handleMagnet:text];
			[self.navigationController popViewControllerAnimated:YES];
		}
		else if ([text rangeOfString:@".torrent"].location != NSNotFound)
		{
			[[TorrentDelegate sharedInstance] handleTorrentFile:text];
			[self.navigationController popViewControllerAnimated:YES];
		}
		else
		{
			if ([text rangeOfString:@"https://"].location != NSNotFound || [text rangeOfString:@"http://"].location != NSNotFound)
			{
				SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:text];
				[self.navigationController presentViewController:webViewController animated:YES completion:nil];
			}
			else
			{
				SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:[@"http://" stringByAppendingString:[text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
				[self.navigationController presentViewController:webViewController animated:YES completion:nil];
			}
		}
	}
    [textField resignFirstResponder];
    return YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
	[TorrentDelegate.sharedInstance.currentlySelectedClient showNotification:nil];
	[self.textBox resignFirstResponder];
	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:nil action:nil];
	[super viewWillDisappear:animated];
}

@end
