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

#define IPHONE_HEIGHT 22
#define IPAD_HEIGHT 28

@implementation TorrentJobsViewController

- (id)init
{
	if (self = [super init])
	{
		headerView = nil;
	}
	return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Prototype";
	
    TorrentJobCheckerCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
    if (cell == nil)
	{
        cell = [[TorrentJobCheckerCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    jobsDict = [[[TorrentDelegate sharedInstance] currentlySelectedClient] getJobsDict];

	//Convert the contents of the outer dictionary to a mutable array
	NSMutableArray *dictValues = [[jobsDict allValues] mutableCopy];
	[dictValues sortUsingComparator: (NSComparator)^(NSDictionary *a, NSDictionary *b){
		NSNumber *key1 = a[@"progress"];
		NSNumber *key2 = b[@"progress"];
		if ([key1 compare:key2] != NSOrderedSame)
		{
			return [key1 compare:key2];
		}
		
		return [a[@"name"] compare:b[@"name"]];
	}];
	sortedKeys = dictValues;
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
	double completeValue = [[[[[TorrentDelegate sharedInstance] currentlySelectedClient] class] completeNumber] floatValue];
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
			label.text = @"Host Offline";
			label.font = [UIFont fontWithName:@"Arial" size:[self sizeForDevice] - 4];
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