//
//  AboutViewController.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 31/12/2013.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "AboutViewController.h"

@implementation AboutViewController

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

	if ([cell.textLabel.text isEqualToString:@"Version"])
	{
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
	}

	return cell;
}

@end