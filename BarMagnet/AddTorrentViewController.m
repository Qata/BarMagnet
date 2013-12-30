//
//  AddTorrentViewController.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 15/07/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "AddTorrentViewController.h"
#import "TorrentDelegate.h"
#import "FileHandler.h"
#import "TorrentClient.h"
#import "SVWebViewController.h"

@interface AddTorrentViewController ()

@end

@implementation AddTorrentViewController

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if ([textField isEqual:[self textBox]])
	{
		[self addTorrent];
	}
	else if ([textField isEqual:[self searchBox]])
	{
		NSString * query = [[FileHandler sharedInstance] settingsValueForKey:@"query_format"];
		if ([[textField text] length] && [query length])
		{
			if ([query rangeOfString:@"https://"].location != NSNotFound)
			{
				SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:[query stringByReplacingOccurrencesOfString:@"%query%" withString:[[textField text] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
				webViewController.reference = self;
				[self.navigationController presentViewController:webViewController animated:YES completion:nil];
			}
			else
			{
				SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:[@"http://" stringByAppendingString:[query stringByReplacingOccurrencesOfString:@"%query%" withString:[[textField text] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]];
				webViewController.reference = self;
				[self.navigationController presentViewController:webViewController animated:YES completion:nil];
			}
		}
	}
    [textField resignFirstResponder];
    return YES;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	[self setTitle:@"Add Torrent"];
	[[self searchBox] becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[[[TorrentDelegate sharedInstance] currentlySelectedClient] showNotification:nil];
	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:nil action:nil];
	[super viewWillDisappear:animated];
}

- (IBAction)openSiteButton:(id)sender
{
	NSString * site = [[FileHandler sharedInstance] settingsValueForKey:@"preferred_torrent_site"];
	if ([site length])
	{
		if ([site rangeOfString:@"https://"].location != NSNotFound)
		{
			SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:site];
			[self.navigationController presentViewController:webViewController animated:YES completion:nil];
		}
		else
		{
			SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:[@"http://" stringByAppendingString:site]];
			[self.navigationController presentViewController:webViewController animated:YES completion:nil];
		}
	}
}

- (void)addTorrent
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
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{

}

- (BOOL)shouldAutorotate
{
	return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait;
}

@end
