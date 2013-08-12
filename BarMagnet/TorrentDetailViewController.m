//
//  TorrentDetailViewController.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 9/07/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "TorrentDetailViewController.h"
#import "TorrentDictFunctions.h"
#import "TorrentDelegate.h"
#import "TorrentClient.h"

@implementation TorrentDetailViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	hashDict = [[[TorrentDelegate sharedInstance] currentlySelectedClient] getJobsDict][hashString];
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
	[self setTitle:hashDict[@"name"]];
	identifierArray = @[@[@"", @"Size", @"Downloaded", @"Uploaded", @"Completed"], @[@"Download", @"Upload", @"Seeds Connected", @"Peers Connected", @"ETA"]];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:nil action:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	identifierArray = nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *CellIdentifier;
	if (![indexPath section] && ![indexPath row])
	{
		CellIdentifier = @"RegularCell";
	}
	else
	{
		CellIdentifier = @"TorrentDetailCell";
	}

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil)
	{
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

	cell.textLabel.text = [[identifierArray objectAtIndex:[indexPath section]] objectAtIndex:[indexPath row]];
	cell.accessoryType = UITableViewCellAccessoryNone;

	double completeValue;
	switch (indexPath.section)
	{
		case 0:
			switch (indexPath.row)
			{
				case 0:
					cell.textLabel.text = [TorrentDictFunctions jobStatusFromCurrentJob:hashDict];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				case 1:
					cell.detailTextLabel.text = [hashDict[@"size"] sizeString];
					break;
				case 2:
					cell.detailTextLabel.text = hashDict[@"downloaded"];
					break;
				case 3:
					cell.detailTextLabel.text = hashDict[@"uploaded"];
					break;
				case 4:
					completeValue = [[[[[TorrentDelegate sharedInstance] currentlySelectedClient] class] completeNumber] floatValue];
					cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1f%%", completeValue ? [hashDict[@"progress"] floatValue] / completeValue * 100 : [hashDict[@"progress"] floatValue] / [hashDict[@"size"] floatValue]];
				default:
					break;
			}
			break;
		case 1:
			switch (indexPath.row)
			{
				case 0:
					cell.detailTextLabel.text = hashDict[@"downloadSpeed"];
					break;
				case 1:
					cell.detailTextLabel.text = hashDict[@"uploadSpeed"];
					break;
				case 2:
					cell.detailTextLabel.text = hashDict[@"seedsConnected"];
					break;
				case 3:
					cell.detailTextLabel.text = hashDict[@"peersConnected"];
					break;
				case 4:
					cell.detailTextLabel.text = hashDict[@"ETA"];
					break;
				default:
					break;
			}
			break;
		default:
			break;
	}

	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section)
	{
		case 0:
			return 5;
			break;
		case 1:
			return 5;
			break;
		default:
			return 0;
			break;
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (!(hashDict = [[[TorrentDelegate sharedInstance] currentlySelectedClient] getJobsDict][hashString]))
	{
		[[self navigationController] popToRootViewControllerAnimated:YES];
		return 0;
	}
	[self setTitle:hashDict[@"name"]];
	return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section == 0)
		return hashDict[@"name"];
	return @"";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (!indexPath.section && !indexPath.row)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"push_control_view" object:nil userInfo:@{@"indexPath":indexPath, @"hash":hashString, @"storyboardID":@"controlView", @"tableView":tableView}];
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
