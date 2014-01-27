//
//  QueryTableViewController.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 24/01/2014.
//  Copyright (c) 2014 Carlo Tortorella. All rights reserved.
//

#import "QueryCell.h"
#import "QueryTableViewController.h"
#import "SVModalWebViewController.h"
#import "AddQueryTableViewController.h"

@interface QueryTableViewController () <UITextFieldDelegate>
@end

@implementation QueryTableViewController

- (BOOL)textFieldShouldReturn:(UITextField_UniqueString *)textField
{
	if ([[textField text] length] && [textField.uniqueString length])
	{
		SVModalWebViewController *webViewController = [SVModalWebViewController.alloc initWithAddress:[NSString stringWithFormat:@"%@%@", [textField.uniqueString rangeOfString:@"https://"].location != NSNotFound ? @"" : @"http://", [textField.uniqueString stringByReplacingOccurrencesOfString:@"%query%" withString:[[textField text] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]];
		[self.navigationController presentViewController:webViewController animated:YES completion:nil];
	}
	return [textField resignFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:nil action:nil];
	[super viewWillDisappear:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[NSUserDefaults.standardUserDefaults objectForKey:@"queries"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary * query = [NSUserDefaults.standardUserDefaults objectForKey:@"queries"][indexPath.row];

	NSString * cellIdentifier = @"Query";
	if (![query[@"uses_query"] boolValue])
	{
		cellIdentifier = @"Static";
	}
	QueryCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	cell.name.text = query[@"name"];
	cell.queryField.text = @"";
	cell.queryField.delegate = self;
	cell.queryField.uniqueString = query[@"query"];
	cell.queryDictionary = query;
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (![[NSUserDefaults.standardUserDefaults objectForKey:@"queries"][indexPath.row][@"uses_query"] boolValue])
	{
		NSString * query = [NSUserDefaults.standardUserDefaults objectForKey:@"queries"][indexPath.row][@"query"];
		SVModalWebViewController *webViewController = [SVModalWebViewController.alloc initWithAddress:[NSString stringWithFormat:@"%@%@", [query rangeOfString:@"https://"].location != NSNotFound ? @"" : @"http://", query]];
		[self.navigationController presentViewController:webViewController animated:YES completion:nil];
	}
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"editQuery" sender:[tableView cellForRowAtIndexPath:indexPath]];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		NSMutableArray * array = [[NSUserDefaults.standardUserDefaults objectForKey:@"queries"] mutableCopy];
		[array removeObjectAtIndex:indexPath.row];
		[NSUserDefaults.standardUserDefaults setObject:array forKey:@"queries"];
		[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.destinationViewController respondsToSelector:@selector(setQueryDictionary:)])
	{
		if ([sender respondsToSelector:@selector(queryDictionary)])
		{
			[segue.destinationViewController setQueryDictionary:[sender queryDictionary]];
		}
	}
}

@end