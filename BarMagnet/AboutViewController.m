//
//  AboutViewController.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 31/12/2013.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "AboutViewController.h"
#import "SVModalWebViewController.h"

@implementation AboutViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.title = [NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleName"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

	if ([cell.textLabel.text isEqualToString:@"Version"])
	{
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
	}

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0 && indexPath.row == 2)
	{
		[UIApplication.sharedApplication openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=CAFZNLKE6ZRR6"]];
		//[self presentViewController:[[SVModalWebViewController alloc] initWithAddress:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=CAFZNLKE6ZRR6"] animated:YES completion:nil];
	}
}

@end