//
//  TorrentControlViewController.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 14/07/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "TorrentControlViewController.h"
#import "TorrentDelegate.h"
#import "TorrentDictFunctions.h"
#import "TorrentJobChecker.h"
#import "TorrentClient.h"

@implementation TorrentControlViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	hashDict = [[[TorrentDelegate sharedInstance] currentlySelectedClient] getJobsDict][hashString];
	[self setTitle:@"Control"];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"uncancel_refresh" object:nil];
	[torrentJobsView deselectRowAtIndexPath:[torrentJobsView indexPathForSelectedRow] animated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *CellIdentifier;
	if (![indexPath section] && ![indexPath row])
	{
		CellIdentifier = @"StatusCell";
	}
	else
	{
		CellIdentifier = @"RegularCell";
	}

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil)
	{
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }

	switch (indexPath.section)
	{
		case 0:
			cell.textLabel.text = [TorrentDictFunctions jobStatusFromCurrentJob:hashDict];
			break;
		case 1:
			switch (indexPath.row)
			{
				case 0:
					if ([[hashDict objectForKey:@"status"] isEqual:@"Paused"])
					{
						cell.textLabel.text = @"Resume";
					}
					else
					{
						cell.textLabel.text = @"Pause";
					}
					break;
				case 1:
					cell.textLabel.text = @"Remove Torrent";
					break;
			}
			break;
	}

	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section)
	{
		case 0:
			return 1;
			break;
		case 1:
			return 2;
			break;
	}
	return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	selfView = tableView;
	if (!(hashDict = [[[[TorrentDelegate sharedInstance] currentlySelectedClient] getJobsDict] objectForKey:hashString]))
	{
		[[self navigationController] popToRootViewControllerAnimated:YES];
		return 0;
	}
	return 2;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section)
	{
		case 1:
			switch (indexPath.row)
			{
				case 0:
					if ([[hashDict objectForKey:@"status"] isEqual:@"Paused"])
						[[[TorrentDelegate sharedInstance] currentlySelectedClient] resumeTorrent:hashString];
					else
						[[[TorrentDelegate sharedInstance] currentlySelectedClient] pauseTorrent:hashString];
					[[self navigationController] popToRootViewControllerAnimated:YES];
					break;
				case 1:
					[self showActionSheet];
					break;
			}
			break;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section == 0)
		return [hashDict objectForKey:@"name"];
	return nil;
}

- (void)showActionSheet
{
    UIActionSheet *popupQuery;
	if ([[[TorrentDelegate sharedInstance] currentlySelectedClient] supportsEraseChoice])
	{
		popupQuery = [[UIActionSheet alloc] initWithTitle:@"Also delete data?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete Data" otherButtonTitles:@"Delete Torrent", nil];
	}
	else
	{
		popupQuery = [[UIActionSheet alloc] initWithTitle:@"Are you sure?" delegate:self cancelButtonTitle:@"Whoa, cancel!" destructiveButtonTitle:@"Yes!" otherButtonTitles:nil];
	}
    [popupQuery showFromTabBar:[[self tabBarController] tabBar]];
	[selfView deselectRowAtIndexPath:[selfView indexPathForSelectedRow] animated:NO];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex)
	{
		 case 0:
			[[[TorrentDelegate sharedInstance] currentlySelectedClient] removeTorrent:hashString removeData:YES];
			[[self navigationController] popToRootViewControllerAnimated:YES];
			break;
		 case 1:
			if (![[[TorrentDelegate sharedInstance] currentlySelectedClient] supportsEraseChoice])
			{
				[[[TorrentDelegate sharedInstance] currentlySelectedClient] removeTorrent:hashString removeData:NO];
				[[self navigationController] popToRootViewControllerAnimated:YES];
			}
			break;
	}
}

- (void)setHash:(NSString *)hash
{
	hashString = hash;
}

- (void)setJobsView:(UITableView *)jobsView
{
	torrentJobsView = jobsView;
}

@end
