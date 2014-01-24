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

@interface QueryTableViewController () <UITextFieldDelegate>

@end

@implementation QueryTableViewController

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	NSString * query = [NSUserDefaults.standardUserDefaults objectForKey:@"queries"][textField.tag][@"query"];
	if ([[textField text] length] && [query length])
	{
		SVModalWebViewController *webViewController = [SVModalWebViewController.alloc initWithAddress:[NSString stringWithFormat:@"%@%@", [query rangeOfString:@"https://"].location != NSNotFound ? @"" : @"http://", [query stringByReplacingOccurrencesOfString:@"%query%" withString:[[textField text] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]];
		[self.navigationController presentViewController:webViewController animated:YES completion:nil];
	}
	return [textField resignFirstResponder];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.tableView reloadData];
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
	QueryCell * cell = [tableView dequeueReusableCellWithIdentifier:@"Query"];
	cell.name = query[@"name"];
	cell.queryField.delegate = self;
	cell.queryField.tag = indexPath.row;
	return cell;
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

@end