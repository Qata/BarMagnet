//
//  TorrentJobsViewController.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 29/06/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "TorrentDetailViewController.h"
#import "TorrentJobsViewController.h"
#import "TorrentJobCheckerCell.h"
#import "TorrentDelegate.h"
#import "TorrentClient.h"
#import "TorrentDictFunctions.h"
#import "FileHandler.h"

#define IPHONE_HEIGHT 22
#define IPAD_HEIGHT 28

@interface TorrentJobsViewController ()
@property (nonatomic, weak) UITableView * tableView;
@end

@implementation TorrentJobsViewController

- (id)init
{
	if (self = [super init])
	{
		headerView = nil;
	}
	return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    jobsDict = [[[TorrentDelegate sharedInstance] currentlySelectedClient] getJobsDict];
	NSMutableArray *dictValues = [[jobsDict allValues] mutableCopy];

	NSString * sortBy = [[FileHandler sharedInstance] settingsValueForKey:@"sort_by"];

	if ([sortBy isEqualToString:@"completed"])
	{
		[dictValues sortUsingComparator: (NSComparator)^(NSDictionary *a, NSDictionary *b){
			double completeValue = [[[[[TorrentDelegate sharedInstance] currentlySelectedClient] class] completeNumber] doubleValue];
			if ([a[@"progress"] doubleValue] == completeValue)
			{
				if (!([b[@"progress"] doubleValue] == completeValue))
				{
					return [@0 compare:@1];
				}
			}
			else if ([b[@"progress"] doubleValue] == completeValue)
			{
				return [@1 compare:@0];
			}

			NSNumber *key1 = a[@"progress"];
			NSNumber *key2 = b[@"progress"];
			if ([key2 compare:key1] != NSOrderedSame)
			{
				return [key2 compare:key1];
			}

			return [a[@"name"] compare:b[@"name"]];
		}];
	}
	else if ([sortBy isEqualToString:@"incomplete"])
	{
		[dictValues sortUsingComparator: (NSComparator)^(NSDictionary *a, NSDictionary *b){
			double completeValue = [[[[[TorrentDelegate sharedInstance] currentlySelectedClient] class] completeNumber] doubleValue];
			if ([a[@"progress"] doubleValue] == completeValue)
			{
				if (!([b[@"progress"] doubleValue] == completeValue))
				{
					return [@1 compare:@0];
				}
			}
			else if ([b[@"progress"] doubleValue] == completeValue)
			{
				return [@0 compare:@1];
			}

			NSNumber *key1 = a[@"progress"];
			NSNumber *key2 = b[@"progress"];
			if ([key1 compare:key2] != NSOrderedSame)
			{
				return [key1 compare:key2];
			}

			return [a[@"name"] compare:b[@"name"]];
		}];
	}
	else if ([sortBy isEqualToString:@"Downloading"] || [sortBy isEqualToString:@"Seeding"] || [sortBy isEqualToString:@"Paused"])
	{
		[dictValues sortUsingComparator: (NSComparator)^(NSDictionary *a, NSDictionary *b){
			if ([a[@"status"] isEqualToString:sortBy])
			{
				if (![b[@"status"] isEqualToString:sortBy])
				{
					return [@0 compare:@1];
				}
			}
			else if ([b[@"status"] isEqualToString:sortBy])
			{
				return [@1 compare:@0];
			}

			return [a[@"name"] compare:b[@"name"]];
		}];
	}
	sortedKeys = dictValues;
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Prototype";
	
    TorrentJobCheckerCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	NSDictionary * currentJob;
	if ([[jobsDict allKeys] count])
	{
		currentJob = [jobsDict objectForKey:[[jobsDict allKeys] objectAtIndex:[[jobsDict allValues] indexOfObject:[sortedKeys objectAtIndex:indexPath.row]]]];
	}
	else
	{
		return nil;
	}

	cell.name.text = currentJob[@"name"];

	cell.downloadSpeed.text = [NSString stringWithFormat:@"Down: %@", currentJob[@"downloadSpeed"]];
	cell.uploadSpeed.text = [NSString stringWithFormat:@"Up: %@", currentJob[@"uploadSpeed"]];
	cell.ETA.text = [currentJob[@"ETA"] length] ? [NSString stringWithFormat:@"ETA: %@", currentJob[@"ETA"]] : @"";
	double completeValue = [[[[[TorrentDelegate sharedInstance] currentlySelectedClient] class] completeNumber] doubleValue];
	completeValue ? [cell.percentBar setProgress:([currentJob[@"progress"] floatValue] / completeValue)] : nil;
	[[cell percentBar] setHidden:!completeValue];

	cell.currentStatus.text = [TorrentDictFunctions jobStatusFromCurrentJob:currentJob];

	cell.currentStatus.textAlignment = NSTextAlignmentRight;
	cell.ETA.textAlignment = NSTextAlignmentRight;
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	{
		cell.downloadSpeed.font = [UIFont fontWithName:@"Arial-BoldMT" size:10];
		for (UILabel * label in @[cell.uploadSpeed, cell.currentStatus, cell.ETA])
		{
			label.font = [UIFont fontWithName:@"Arial" size:10];
		}
	}

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.tableView = tableView;
	UIActionSheet *popupQuery;
	if (TorrentDelegate.sharedInstance.currentlySelectedClient.supportsEraseChoice)
	{
		popupQuery = [[UIActionSheet alloc] initWithTitle:@"Also delete data?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete Data" otherButtonTitles:@"Delete Torrent", nil];
	}
	else
	{
		popupQuery = [[UIActionSheet alloc] initWithTitle:@"Are you sure?" delegate:self cancelButtonTitle:@"Whoa, cancel!" destructiveButtonTitle:@"Yes!" otherButtonTitles:nil];
	}
	popupQuery.tag = indexPath.row;
	[popupQuery showFromToolbar:self.viewController.navigationController.toolbar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != [actionSheet cancelButtonIndex])
	{
		NSString * hashString = [[jobsDict allKeys] objectAtIndex:[[jobsDict allValues] indexOfObject:[sortedKeys objectAtIndex:actionSheet.tag]]];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"cancel_refresh" object:nil];
		[[[TorrentDelegate sharedInstance] currentlySelectedClient] addTemporaryDeletedJobsObject:@2 forKey:hashString];
		[[[TorrentDelegate sharedInstance] currentlySelectedClient] removeTorrent:hashString removeData:buttonIndex == 0];
		[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:actionSheet.tag inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
	}
	else
	{
		[self.tableView setEditing:NO animated:YES];
	}
}

- (CGFloat)sizeForDevice
{
	return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone ? IPHONE_HEIGHT : IPAD_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return [self sizeForDevice];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	if (!section)
	{
		if (headerView)
		{
			UILabel * label = ((UILabel *)[headerView viewWithTag:1]);
			[label setText:[[[TorrentDelegate sharedInstance] currentlySelectedClient] isHostOnline] ? @"Host Online" : @"Host Offline"];
			return headerView;
		}
		else
		{
			headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [tableView frame].size.width, 0)];
			headerView.backgroundColor = [UIColor colorWithRed:77/255. green:149/255. blue:197/255. alpha:0.85];
			UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [tableView frame].size.width, [self sizeForDevice])];
			[headerView addSubview:label];
			label.backgroundColor = [UIColor clearColor];
			label.textColor = [UIColor whiteColor];
			label.text = @"Host Unreachable";
			label.font = [UIFont fontWithName:@"Arial" size:[self sizeForDevice] - 6];
			label.textAlignment = NSTextAlignmentCenter;
			label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
			label.tag = 1;
			return headerView;
		}
	}
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[[[TorrentDelegate sharedInstance] currentlySelectedClient] getJobsDict] allKeys] count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"push_detail_view" object:nil userInfo:@{@"indexPath":indexPath, @"hash":[[jobsDict allKeys] objectAtIndex:[[jobsDict allValues] indexOfObject:[sortedKeys objectAtIndex:indexPath.row]]], @"storyboardID":@"detailView", @"tableView":tableView}];
}

@end