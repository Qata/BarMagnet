//
//  FirstViewController.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 4/06/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "TorrentJobsTableViewController.h"
#import "FileHandler.h"
#import "TorrentDelegate.h"
#import "SVWebViewController.h"
#import "TSMessages/Classes/TSMessage.h"
#import "TorrentJobCheckerCell.h"
#import "TorrentDictFunctions.h"

#define IPHONE_HEIGHT 22
#define IPAD_HEIGHT 28

@interface TorrentJobsTableViewController () <UIActionSheetDelegate, UIAlertViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate>
@property (nonatomic, weak) UIActionSheet * controlSheet;
@property (nonatomic, weak) UIActionSheet * sortBySheet;
@property (nonatomic, weak) UIActionSheet * deleteTorrentSheet;
@property (nonatomic, strong) NSArray * sortByStrings;
@property (nonatomic, assign) BOOL shouldRefresh;
@property (nonatomic, strong) NSMutableArray * filteredArray;
@property (nonatomic, strong) UIView * headerView;
@end

@implementation TorrentJobsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self setTitle:@"Torrents"];
	self.sortByStrings = @[@"Completed", @"Incomplete", @"Downloading", @"Seeding", @"Paused", @"Name"];
	[[[TorrentDelegate sharedInstance] currentlySelectedClient] setDefaultViewController:self.navigationController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveUpdateTableNotification) name:@"update_torrent_jobs_table" object:nil];
	self.shouldRefresh = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self.tableView reloadData];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)receiveUpdateTableNotification
{
	if (!cancelNextRefresh && !self.tableView.isEditing)
	{
		if (self.shouldRefresh)
		{
			[self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
		}
		[tdv.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
	}
	else
	{
		cancelNextRefresh = NO;
	}
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
	self.shouldRefresh = NO;
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
	self.shouldRefresh = YES;
	[self receiveUpdateTableNotification];
}

- (IBAction)addTorrentPopup:(id)sender
{
	UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Open URL", @"Search Query", @"Open Torrent Site", nil];
	alert.alertViewStyle = UIAlertViewStylePlainTextInput;
	[alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString * text = [[alertView textFieldAtIndex:0] text];
	if (alertView.alertViewStyle == UIAlertViewStylePlainTextInput)
	{
		switch (buttonIndex)
		{
			case 1:
			{
				if ([text length])
				{
					NSString * magnet = @"magnet:";
					if (text.length > magnet.length && [[text substringWithRange:NSMakeRange(0, magnet.length)] isEqual:magnet])
					{
						[[TorrentDelegate sharedInstance] handleMagnet:text];
						[self.navigationController popViewControllerAnimated:YES];
					}
					else if ([text rangeOfString:@".torrent"].location != NSNotFound)
					{
						[[TorrentDelegate sharedInstance] handleTorrentFile:text];
						[self.navigationController popViewControllerAnimated:YES];
					}
					else
					{
						if ([text rangeOfString:@"https://"].location != NSNotFound || [text rangeOfString:@"http://"].location != NSNotFound)
						{
							SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:text];
							[self.navigationController presentViewController:webViewController animated:YES completion:nil];
						}
						else
						{
							SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:[@"http://" stringByAppendingString:[text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
							[self.navigationController presentViewController:webViewController animated:YES completion:nil];
						}
					}
				}
				break;
			}
			case 2:
			{
				NSString * query = [[FileHandler sharedInstance] settingsValueForKey:@"query_format"];
				if ([text length] && [query length])
				{
					if ([query rangeOfString:@"https://"].location != NSNotFound)
					{
						SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:[query stringByReplacingOccurrencesOfString:@"%query%" withString:[text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
						webViewController.reference = self;
						[self.navigationController presentViewController:webViewController animated:YES completion:nil];
					}
					else
					{
						SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:[@"http://" stringByAppendingString:[query stringByReplacingOccurrencesOfString:@"%query%" withString:[text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]];
						webViewController.reference = self;
						[self.navigationController presentViewController:webViewController animated:YES completion:nil];
					}
				}
				break;
			}
			case 3:
			{
				NSString * site = [[FileHandler sharedInstance] settingsValueForKey:@"preferred_torrent_site"];
				if ([site length])
				{
					if ([site rangeOfString:@"https://"].location != NSNotFound)
					{
						SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:site];
						[self presentViewController:webViewController animated:YES completion:nil];
					}
					else
					{
						SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:[@"http://" stringByAppendingString:site]];
						[self presentViewController:webViewController animated:YES completion:nil];
					}
				}
				break;
			}
		}
	}
}

- (IBAction)showListOfControlOptions:(id)sender
{
	[[self.controlSheet = UIActionSheet.alloc initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Resume All", @"Pause All", nil] showFromToolbar:self.navigationController.toolbar];
}

- (IBAction)sortBy:(id)sender
{
	[[self.sortBySheet = UIActionSheet.alloc initWithTitle:@"Sort By" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Completed", @"Incomplete", @"Downloading", @"Seeding", @"Paused", @"Name", @"Size", nil] showFromToolbar:self.navigationController.toolbar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != actionSheet.cancelButtonIndex)
	{
		if (actionSheet == self.sortBySheet)
		{
			[FileHandler.sharedInstance setSettingsValue:[actionSheet buttonTitleAtIndex:buttonIndex] forKey:@"sort_by"];
			[self.tableView reloadData];
		}
		else if (actionSheet == self.controlSheet)
		{
			switch (buttonIndex)
			{
				case 0:
					[TorrentDelegate.sharedInstance.currentlySelectedClient resumeAllTorrents];
					break;
				case 1:
					[TorrentDelegate.sharedInstance.currentlySelectedClient pauseAllTorrents];
					break;
			}
		}
		else if (actionSheet == self.deleteTorrentSheet)
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
	}
}

- (IBAction)openUI:(id)sender
{
	if ([[[[TorrentDelegate sharedInstance] currentlySelectedClient] getUserFriendlyAppendedURL] length])
	{
		SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:[[[TorrentDelegate sharedInstance] currentlySelectedClient] getUserFriendlyAppendedURL]];
		[self presentViewController:webViewController animated:YES completion:nil];
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    jobsDict = [[[TorrentDelegate sharedInstance] currentlySelectedClient] getJobsDict];
	NSMutableArray *dictValues = [[jobsDict allValues] mutableCopy];

	NSString * sortBy = [[FileHandler sharedInstance] settingsValueForKey:@"sort_by"];

	if ([sortBy isEqualToString:@"Completed"])
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
	else if ([sortBy isEqualToString:@"Incomplete"])
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
	else if ([sortBy isEqualToString:@"Name"])
	{
		[dictValues sortUsingComparator: (NSComparator)^(NSDictionary *a, NSDictionary *b){
			return [a[@"name"] compare:b[@"name"]];
		}];
	}
	else if ([sortBy isEqualToString:@"Size"])
	{
		[dictValues sortUsingComparator: (NSComparator)^(NSDictionary *a, NSDictionary *b){
			return [a[@"size"] compare:b[@"size"]];
		}];
	}
	sortedKeys = dictValues;
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
		UITableViewCell * cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
		cell.textLabel.text = self.filteredArray[indexPath.row][@"name"];
		return cell;
    }

	static NSString *CellIdentifier = @"Prototype";

	TorrentJobCheckerCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	NSDictionary * currentJob = [jobsDict objectForKey:[[jobsDict allKeys] objectAtIndex:[[jobsDict allValues] indexOfObject:[sortedKeys objectAtIndex:indexPath.row]]]];

	cell.name.text = currentJob[@"name"];
	cell.uploadSpeed.text = [NSString stringWithFormat:@"↑ %@", currentJob[@"uploadSpeed"]];
	cell.downloadSpeed.text = [NSString stringWithFormat:@"↓ %@", currentJob[@"downloadSpeed"]];
	cell.ETA.text = [currentJob[@"ETA"] length] ? [NSString stringWithFormat:@"ETA: %@", currentJob[@"ETA"]] : @"";
	double completeValue = [[[[[TorrentDelegate sharedInstance] currentlySelectedClient] class] completeNumber] doubleValue];
	completeValue ? [cell.percentBar setProgress:[currentJob[@"progress"] floatValue] / completeValue] : nil;
	[[cell percentBar] setHidden:!completeValue];

	cell.currentStatus.text = [TorrentDictFunctions jobStatusFromCurrentJob:currentJob];

	cell.currentStatus.textAlignment = NSTextAlignmentRight;
	cell.ETA.textAlignment = NSTextAlignmentRight;
	cell.hashString = currentJob[@"hash"];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	{
		cell.downloadSpeed.font = [UIFont fontWithName:@"Arial-BoldMT" size:10];
		UIFont * font = [UIFont fontWithName:@"Arial" size:10];
		cell.uploadSpeed.font = font;
		cell.currentStatus.font = font;
		cell.ETA.font = font;
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
		popupQuery = [[UIActionSheet alloc] initWithTitle:@"Are you sure?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Yes" otherButtonTitles:nil];
	}
	self.deleteTorrentSheet = popupQuery;
	popupQuery.tag = indexPath.row;
	[popupQuery showFromToolbar:self.navigationController.toolbar];
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
	if (!self.shouldRefresh)
		return nil;
	if (self.headerView)
	{
		UILabel * label = (UILabel *)self.headerView.subviews.lastObject;
		if ([[[TorrentDelegate sharedInstance] currentlySelectedClient] isHostOnline])
		{
			self.headerView.backgroundColor = [UIColor colorWithRed:77/255. green:149/255. blue:197/255. alpha:0.85];
			label.text = @"Host Online";
		}
		else
		{
			self.headerView.backgroundColor = [UIColor colorWithRed:250/255. green:50/255. blue:50/255. alpha:0.85];
			label.text = @"Host Offline";
		}
	}
	else
	{
		self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [tableView frame].size.width, 0)];
		self.headerView.backgroundColor = [UIColor colorWithRed:250/255. green:50/255. blue:50/255. alpha:0.85];
		UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [tableView frame].size.width, [self sizeForDevice])];
		[self.headerView addSubview:label];
		label.backgroundColor = [UIColor clearColor];
		label.textColor = [UIColor whiteColor];
		label.text = @"Host Offline";
		label.font = [UIFont fontWithName:@"Arial" size:[self sizeForDevice] - 6];
		label.textAlignment = NSTextAlignmentCenter;
		label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	}
	return self.headerView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
		return self.filteredArray.count;
	}
    return [[[[[TorrentDelegate sharedInstance] currentlySelectedClient] getJobsDict] allKeys] count];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.destinationViewController isKindOfClass:TorrentDetailViewController.class])
	{
		tdv = segue.destinationViewController;
		if ([sender isKindOfClass:TorrentJobCheckerCell.class])
		{
			[segue.destinationViewController setHashString:[sender hashString]];
		}
		else if ([sender isKindOfClass:NSString.class])
		{
			[segue.destinationViewController setHashString:sender];
		}
	}
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    return YES;
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    return YES;
}

- (void)filterContentForSearchText:(NSString *)searchText scope:(NSString *)scope
{
	self.filteredArray = NSMutableArray.new;
	NSDictionary * jobs = [[[TorrentDelegate sharedInstance] currentlySelectedClient] getJobsDict];
	for (NSDictionary * job in jobs.allValues)
	{
		if ([[job[@"name"] lowercaseString] rangeOfString:[searchText lowercaseString]].location != NSNotFound)
		{
			[self.filteredArray addObject:job];
		}
	}
	[self.filteredArray sortUsingComparator: (NSComparator)^(NSDictionary *a, NSDictionary *b){
		return [a[@"name"] compare:b[@"name"]];
	}];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
		[self performSegueWithIdentifier:@"detail" sender:self.filteredArray[indexPath.row][@"hash"]];
	}
}

@end
