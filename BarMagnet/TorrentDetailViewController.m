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

@interface TorrentDetailViewController () <UIActionSheetDelegate>

@end

@implementation TorrentDetailViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	hashDict = [TorrentDelegate.sharedInstance.currentlySelectedClient getJobsDict][self.hashString];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self setTitle:hashDict[@"name"]];
	identifierArray = @[@[@"", @"Size", @"Downloaded", @"Uploaded", @"Completed"], @[@"Download", @"Upload", @"Seeds Connected", @"Peers Connected", @"ETA"]];
}

- (void)viewWillDisappear:(BOOL)animated
{
	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:nil action:nil];
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	identifierArray = nil;
	[super viewDidDisappear:animated];
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

	cell.textLabel.text = [[identifierArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];

	double completeValue;
	switch (indexPath.section)
	{
		case 0:
			switch (indexPath.row)
			{
				case 0:
					cell.textLabel.text = [TorrentDictFunctions jobStatusFromCurrentJob:hashDict];
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
					completeValue = [[[TorrentDelegate.sharedInstance.currentlySelectedClient class] completeNumber] floatValue];
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
	self.playPauseButton.image = [UIImage imageNamed:[NSString stringWithFormat:@"UIButtonBar%@", [hashDict[@"status"] isEqualToString:@"Paused"] ? @"Play" : @"Pause"]];

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

- (IBAction)playPause:(id)sender
{
	if ([[hashDict objectForKey:@"status"] isEqual:@"Paused"])
		[TorrentDelegate.sharedInstance.currentlySelectedClient resumeTorrent:self.hashString];
	else
		[TorrentDelegate.sharedInstance.currentlySelectedClient pauseTorrent:self.hashString];
	[self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)deleteTorrent:(id)sender
{
	UIActionSheet *popupQuery;
	if (TorrentDelegate.sharedInstance.currentlySelectedClient.supportsEraseChoice)
	{
		popupQuery = [[UIActionSheet alloc] initWithTitle:@"Also delete data?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete Data" otherButtonTitles:@"Delete Torrent", nil];
	}
	else
	{
		popupQuery = [[UIActionSheet alloc] initWithTitle:@"Are you sure?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Yes" otherButtonTitles:nil];
	}
    [popupQuery showFromToolbar:self.navigationController.toolbar];
	[selfView deselectRowAtIndexPath:[selfView indexPathForSelectedRow] animated:NO];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != [actionSheet cancelButtonIndex])
	{
		[TorrentDelegate.sharedInstance.currentlySelectedClient addTemporaryDeletedJobsObject:@2 forKey:self.hashString];
		[TorrentDelegate.sharedInstance.currentlySelectedClient removeTorrent:self.hashString removeData:buttonIndex == 0];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"update_torrent_jobs_table" object:nil];
		[[self navigationController] popToRootViewControllerAnimated:YES];
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (!(hashDict = [TorrentDelegate.sharedInstance.currentlySelectedClient getJobsDict][self.hashString]))
	{
		[[self navigationController] popToRootViewControllerAnimated:NO];
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

@end
