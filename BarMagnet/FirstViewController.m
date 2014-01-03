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
@property (nonatomic, strong) NSArray * sortByStrings;
@end

@implementation FirstViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self setTitle:@"Torrents"];
	self.sortByStrings = @[@"Completed", @"Incomplete", @"Downloading", @"Seeding", @"Paused", @"Name"];
	[[[TorrentDelegate sharedInstance] currentlySelectedClient] setDefaultViewController:[self navigationController]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveUpdateTableNotification) name:@"update_torrent_jobs_table" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushDetailView:) name:@"push_detail_view" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelNextRefresh) name:@"cancel_refresh" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unCancelNextRefresh) name:@"uncancel_refresh" object:nil];

	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
	{
		
	}
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

- (IBAction)showListOfControlOptions:(id)sender
{
	if ([self.torrentJobsTableView numberOfRowsInSection:0])
	{
		[[self.mainSheet = UIActionSheet.alloc initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Resume All", @"Pause All", nil] showFromToolbar:self.navigationController.toolbar];
		self.mainSheet.tag = 1;
	}
}

- (IBAction)sortBy:(id)sender
{
	if ([self.torrentJobsTableView numberOfRowsInSection:0])
	{
		[[self.mainSheet = UIActionSheet.alloc initWithTitle:@"Sort By" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Completed", @"Incomplete", @"Downloading", @"Seeding", @"Paused", @"Name", @"Size", nil] showFromToolbar:self.navigationController.toolbar];
		self.mainSheet.tag = 0;
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != actionSheet.cancelButtonIndex)
	{
		if (actionSheet.tag == 0)
		{
			[FileHandler.sharedInstance setSettingsValue:[actionSheet buttonTitleAtIndex:buttonIndex] forKey:@"sort_by"];
			[self.torrentJobsTableView reloadData];
		}
		else
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
}

- (void)pushDetailView:(NSNotification *)notification
{
	[self cancelNextRefresh];
	tdv = [self.storyboard instantiateViewControllerWithIdentifier:[notification userInfo][@"storyboardID"]];
	[tdv setHash:[notification userInfo][@"hash"]];
	[tdv setJobsView:[notification userInfo][@"tableView"]];
	[[self navigationController] pushViewController:tdv animated:YES];
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
