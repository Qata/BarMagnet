//
//  AddQueryTableViewController.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 24/01/2014.
//  Copyright (c) 2014 Carlo Tortorella. All rights reserved.
//

#import "AddQueryTableViewController.h"

@implementation AddQueryTableViewController

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	return [textField resignFirstResponder];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.row == 2)
	{
		if (self.name.text.length && self.URL.text.length)
		{
			NSString * URL = [self.URL.text stringByReplacingOccurrencesOfString:@"http://" withString:@""];
			if ([URL rangeOfString:@"%query%"].location != NSNotFound)
			{
				NSMutableArray * array = [[NSUserDefaults.standardUserDefaults objectForKey:@"queries"] mutableCopy];
				[array addObject:@{@"name":self.name.text, @"query":URL}];
				[NSUserDefaults.standardUserDefaults setObject:array forKey:@"queries"];
				[self dismiss:nil];
			}
			else
			{
				[[UIAlertView.alloc initWithTitle:@"Error" message:@"The query URL needs to have \"%query%\" in it somewhere so I know where to put the text" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
			}
		}
	}
}

- (IBAction)dismiss:(id)sender
{
	if ([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] firstObject] integerValue] < 6)
	{
		[self dismissModalViewControllerAnimated:YES];
	}
	else
	{
		[self dismissViewControllerAnimated:YES completion:nil];
	}
}

@end
