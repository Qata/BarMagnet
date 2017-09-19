//
//  TorrentJobsViewController.m
//  BarMagnet
//
//  Created by Charlotte Tortorella on 29/06/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#import "TorrentJobsViewController.h"
#import "TorrentJobCheckerCell.h"
#import "TorrentDelegate.h"
#import "TorrentClient.h"
#define IMAGE_TAG 314159265
#define NAME_TAG 283476564
#define PERCENT_BAR_TAG 218493483
#define DOWN_SPEED_TAG 358979323
#define UP_SPEED_TAG 846264338
#define TOTAL_DOWN_TAG 327950288
#define TOTAL_UP_TAG 419716939
#define STATUS_TAG 128462083

@implementation TorrentJobsViewController

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Prototype";
	
    TorrentJobCheckerCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
	{
		NSLog(@"YOU FUCKED UP");
        cell = [[TorrentJobCheckerCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

	imageView = (UIImageView *)[cell viewWithTag:IMAGE_TAG];
	percentBar = (UIProgressView *)[cell viewWithTag:PERCENT_BAR_TAG];
	torrentName = (UILabel *)[cell viewWithTag:NAME_TAG];
	uploadSpeed = (UILabel *)[cell viewWithTag:UP_SPEED_TAG];
	downloadSpeed = (UILabel *)[cell viewWithTag:DOWN_SPEED_TAG];
	currentStatus = (UILabel *)[cell viewWithTag:STATUS_TAG];
    
    // Set the data for this cell:
    NSDictionary * jobsDict = [[[TorrentDelegate sharedInstance] currentlySelectedClient] getJobsDict];
	NSArray * keysArray = [jobsDict allKeys];

	NSDictionary * currentJob = [jobsDict objectForKey:[keysArray objectAtIndex:indexPath.row]];

	if (![currentJob respondsToSelector:@selector(objectForKey:)])
	{
		currentJob = nil;
	}

	torrentName.text = [currentJob objectForKey:@"name"];

    if ([[jobsDict objectForKey:[keysArray objectAtIndex:indexPath.row]] count] > 1)
    {
		if ([[currentJob objectForKey:@"isPaused"] boolValue])
		{
			imageView.image = [UIImage imageNamed:@"paused"];
		}
        else if ([[currentJob objectForKey:@"progress"] isEqual:[[[[TorrentDelegate sharedInstance] currentlySelectedClient] class] completeNumber]])
        {
			imageView.image = [UIImage imageNamed:@"upload"];
        }
        else if (![[[[[TorrentDelegate sharedInstance] currentlySelectedClient] class] completeNumber] isEqual: [NSNumber numberWithInt:0]])
        {
			imageView.image = [UIImage imageNamed:@"download"];
        }
    }

	downloadSpeed.text = [NSString stringWithFormat:@"Down: %@", [currentJob objectForKey:@"downloadSpeed"]];
	uploadSpeed.text = [NSString stringWithFormat:@"Up: %@", [currentJob objectForKey:@"uploadSpeed"]];

	double completeValue = [[[[[TorrentDelegate sharedInstance] currentlySelectedClient] class] completeNumber] floatValue];
	if (completeValue) //Nobody likes dividing by zero
	{
		[percentBar setHidden:NO];
		[percentBar setProgress:([[currentJob objectForKey:@"progress"] floatValue] / completeValue)];
	}
	else
	{
		[percentBar setHidden:YES];
	}

	if ([[currentJob objectForKey:@"isPaused"] boolValue])
	{
		currentStatus.text = @"Paused";
	}
	else if ([[currentJob objectForKey:@"progress"] isEqual: [[[[TorrentDelegate sharedInstance] currentlySelectedClient] class] completeNumber]])
	{
		currentStatus.text = @"Seeding";
	}
	else
	{
		currentStatus.text = @"Downloading";
	}

	currentStatus.textAlignment = NSTextAlignmentRight;

	downloadSpeed.font = [UIFont fontWithName:@"Arial-BoldMT" size:10];
	NSLog(@"%@", [UIFont fontNamesForFamilyName:@"Arial"]);

	for (UILabel * label in @[currentStatus, uploadSpeed])
	{
		label.font = [UIFont fontWithName:@"Arial" size:10];
	}

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[[[TorrentDelegate sharedInstance] currentlySelectedClient] getJobsDict] allKeys] count];
}

@end
