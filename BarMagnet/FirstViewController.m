//
//  FirstViewController.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 4/06/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "FirstViewController.h"
#import "FileHandler.h"
#import "TorrentDelegate.h"
#import "SVWebViewController.h"
#import "TSMessages/Classes/TSMessage.h"

@interface FirstViewController () <UIActionSheetDelegate>
@property (nonatomic, weak) UIActionSheet * mainSheet;
@end

@implementation FirstViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self setTitle:@"Torrents"];
	[[[TorrentDelegate sharedInstance] currentlySelectedClient] setDefaultViewController:[self navigationController]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveUpdateTableNotification) name:@"update_torrent_jobs_table" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushDetailView:) name:@"push_detail_view" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushControlView:) name:@"push_control_view" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelNextRefresh) name:@"cancel_refresh" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unCancelNextRefresh) name:@"uncancel_refresh" object:nil];
	
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[[self torrentJobsTableView] reloadData];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)receiveUpdateTableNotification
{
	if (!cancelNextRefresh && ![self torrentJobsTableView].isEditing)
	{
		[[self torrentJobsTableView] performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];

		[(UITableView *)[[tdv view] viewWithTag:1] performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
		[(UITableView *)[[tcv view] viewWithTag:1] performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
	}
	else
	{
		cancelNextRefresh = NO;
	}
}

- (void)cancelNextRefresh
{
	cancelNextRefresh = YES;
}

- (void)unCancelNextRefresh
{
	cancelNextRefresh = NO;
}

- (IBAction)showListOfOptions:(id)sender
{
	[[self.mainSheet = UIActionSheet.alloc initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Resume All", @"Pause All", nil] showFromToolbar:self.navigationController.toolbar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != actionSheet.cancelButtonIndex)
	{
		switch (buttonIndex)
		{
			case 0:
				[TorrentDelegate.sharedInstance.currentlySelectedClient resumeAllTorrents];
				break;
			case 1:
				[TorrentDelegate.sharedInstance.currentlySelectedClient pauseAllTorrents];
				break;
		}
	}
}

- (void)pushDetailView:(NSNotification *)notification
{
	[self cancelNextRefresh];
	tdv = [self.storyboard instantiateViewControllerWithIdentifier:[notification userInfo][@"storyboardID"]];
	[tdv setHash:[notification userInfo][@"hash"]];
	[tdv setJobsView:[notification userInfo][@"tableView"]];
	[[self navigationController] pushViewController:tdv animated:YES];
}

- (void)pushControlView:(NSNotification *)notification
{
	[self cancelNextRefresh];
	tcv = [self.storyboard instantiateViewControllerWithIdentifier:[notification userInfo][@"storyboardID"]];
	[tcv setHash:[notification userInfo][@"hash"]];
	[tcv setJobsView:[notification userInfo][@"tableView"]];
	[[self navigationController] pushViewController:tcv animated:YES];
}

- (IBAction)openUI:(id)sender
{
	if ([[[[TorrentDelegate sharedInstance] currentlySelectedClient] getUserFriendlyAppendedURL] length])
	{
		SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:[[[TorrentDelegate sharedInstance] currentlySelectedClient] getUserFriendlyAppendedURL]];
		[self presentViewController:webViewController animated:YES completion:nil];
	}
}
@end
