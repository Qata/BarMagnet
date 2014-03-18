//
//  TorrentDetailViewController.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 9/07/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "TorrentDetailViewController.h"
#import "TorrentDelegate.h"
#import "TorrentClient.h"

@interface TorrentDetailViewController () <UIActionSheetDelegate>
@property (nonatomic, strong) NSArray * identifierArray;
@property (nonatomic, strong) NSDateFormatter * formatter;
@property (nonatomic, weak) TorrentClient * client;
@end

@implementation TorrentDetailViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.client = TorrentDelegate.sharedInstance.currentlySelectedClient;
	self.formatter = NSDateFormatter.new;
	[self.formatter setDateStyle:NSDateFormatterShortStyle];
	[self.formatter setTimeStyle:NSDateFormatterMediumStyle];
	self.identifierArray = @[@[@"", @"Size", @"Downloaded", @"Uploaded", @"Completed", @"Date Added", @"Date Finished"], @[@"Download", @"Upload", @"Seeds Connected", @"Peers Connected", @"Ratio", @"ETA"]];
	hashDict = [TorrentDelegate.sharedInstance.currentlySelectedClient getJobsDict][self.hashString];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveUpdateTableNotification) name:@"update_torrent_jobs_table" object:nil];
	[self receiveUpdateTableNotification];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self setTitle:hashDict[@"name"]];
}

- (void)viewWillDisappear:(BOOL)animated
{
	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:nil action:nil];
	[super viewWillDisappear:animated];
}

- (void)dealloc
{
	[NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)receiveUpdateTableNotification
{
	[self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
	self.playPauseButton.image = [UIImage imageNamed:[NSString stringWithFormat:@"UIButtonBar%@", [hashDict[@"status"] isEqualToString:@"Paused"] ? @"Play" : @"Pause"]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *CellIdentifier;
	if (!([indexPath section] | [indexPath row]))
	{
		CellIdentifier = @"RegularCell";
	}
	else
	{
		CellIdentifier = @"TorrentDetailCell";
	}

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	cell.textLabel.text = [[self.identifierArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];

	switch (indexPath.section)
	{
		case 0:
			switch (indexPath.row)
			{
				case 0:
					cell.textLabel.text = hashDict[@"status"];
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
				{
					double completeValue = [self.client.class completeNumber].doubleValue;
					cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1f%%", completeValue ? [hashDict[@"progress"] doubleValue] / completeValue * 100 : [hashDict[@"progress"] doubleValue] / [hashDict[@"size"] doubleValue]];
					break;
				}
				case 5:
					cell.detailTextLabel.text = [self.formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[hashDict[@"dateAdded"] integerValue]]];
					break;
				case 6:
					cell.detailTextLabel.text = [self.formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[hashDict[@"dateDone"] integerValue]]];
					break;
			}
			break;
		case 1:
			switch (indexPath.row)
			{
				case 0:
					cell.detailTextLabel.text = [hashDict[@"downloadSpeed"] description];
					break;
				case 1:
					cell.detailTextLabel.text = [hashDict[@"uploadSpeed"] description];
					break;
				case 2:
					cell.detailTextLabel.text = [hashDict[@"seedsConnected"] description];
					break;
				case 3:
					cell.detailTextLabel.text = [hashDict[@"peersConnected"] description];
					break;
				case 4:
					cell.detailTextLabel.text = [hashDict[@"ratio"] description];
					break;
				case 5:
					cell.detailTextLabel.text = [hashDict[@"ETA"] description];
					break;
			}
			break;
	}

	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section) {
		case 0:
			return [self.identifierArray[section] count] - 2 + self.client.supportsAddedDate + (self.client.supportsCompletedDate && [hashDict[@"progress"] doubleValue] == [self.client.class completeNumber].doubleValue);
			break;

		default:
			break;
	}
	return [self.identifierArray[section] count];
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
		popupQuery = [[UIActionSheet alloc] initWithTitle:@"Also delete data?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete data" otherButtonTitles:@"Delete torrent", nil];
	}
	else
	{
		popupQuery = [[UIActionSheet alloc] initWithTitle:@"Are you sure?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete torrent" otherButtonTitles:nil];
	}
    [popupQuery showFromToolbar:self.navigationController.toolbar];
	[selfView deselectRowAtIndexPath:[selfView indexPathForSelectedRow] animated:NO];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != [actionSheet cancelButtonIndex])
	{
		[TorrentDelegate.sharedInstance.currentlySelectedClient addTemporaryDeletedJob:8 forKey:self.hashString];
		[TorrentDelegate.sharedInstance.currentlySelectedClient removeTorrent:self.hashString removeData:buttonIndex == 0];
		[NSNotificationCenter.defaultCenter postNotificationName:@"update_torrent_jobs_table" object:nil];
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
	return hashDict[@[@"name", @"hash"][section]];
}

@end
