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
#import "NSOrderedDictionary.h"

#define IPHONE_HEIGHT 22
#define IPAD_HEIGHT 28

enum ORDER
{
	COMPLETED = 1,
	INCOMPLETE,
	DOWNLOAD_SPEED,
	UPLOAD_SPEED,
	ACTIVE,
	DOWNLOADING,
	SEEDING,
	PAUSED,
	NAME,
	SIZE,
	RATIO,
	DATE
};

@interface TorrentJobsTableViewController () <UIActionSheetDelegate, UIAlertViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate, UIScrollViewDelegate>
@property (nonatomic, weak) UIActionSheet * controlSheet;
@property (nonatomic, weak) UIActionSheet * deleteTorrentSheet;
@property (nonatomic, strong) UIActionSheet * sortBySheet;
@property (nonatomic, assign) BOOL shouldRefresh;
@property (nonatomic, strong) NSMutableArray * filteredArray;
@property (nonatomic, strong) UILabel * header;
@property (nonatomic, strong) NSArray * sortedKeys;
@property (nonatomic, strong) NSMutableOrderedDictionary * sortByDictionary;
@end

@implementation TorrentJobsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:nil action:nil];
	self.title = [FileHandler.sharedInstance settingsValueForKey:@"server_name"];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveUpdateTableNotification) name:@"update_torrent_jobs_table" object:nil];
	self.shouldRefresh = YES;
	self.tableView.contentOffset = CGPointMake(0.0, 44.0);

	if (![[[FileHandler.sharedInstance webDataValueForKey:@"url" andDict:nil] orSome:nil] length])
	{
		[self performSegueWithIdentifier:@"Settings" sender:nil];
	}
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(changedClient) name:@"ChangedClient" object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.sortByDictionary = [NSMutableOrderedDictionary.alloc initWithObjects:@[@(COMPLETED), @(INCOMPLETE), @(DOWNLOAD_SPEED), @(UPLOAD_SPEED), @(ACTIVE), @(DOWNLOADING), @(SEEDING), @(PAUSED), @(NAME), @(SIZE), @(RATIO)] pairedWithKeys:@[@"Completed", @"Incomplete", @"Download Speed", @"Upload Speed", @"Active", @"Downloading", @"Seeding", @"Paused", @"Name", @"Size", @"Ratio"]];
	if ([TorrentDelegate.sharedInstance.currentlySelectedClient supportsAddedDate])
	{
		[self.sortByDictionary addObject:@(DATE) pairedWithKey:@"Date Added"];
	}
	self.tableView.rowHeight = [[self.tableView dequeueReusableCellWithIdentifier:[FileHandler.sharedInstance settingsValueForKey:@"cell"]] frame].size.height;
	self.searchDisplayController.searchResultsTableView.rowHeight = [[self.tableView dequeueReusableCellWithIdentifier:[FileHandler.sharedInstance settingsValueForKey:@"cell"]] frame].size.height;
	[self receiveUpdateTableNotification];
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)changedClient
{
	self.title = [FileHandler.sharedInstance settingsValueForKey:@"server_name"];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[self.tableView reloadData];
}

- (void)receiveUpdateTableNotification
{
	if (!cancelNextRefresh)
	{
		if (self.shouldRefresh && !self.tableView.isEditing && !self.tableView.isDragging && !self.tableView.isDecelerating)
		{
			[self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
		}
	}
	else
	{
		cancelNextRefresh = NO;
	}
	[self createDownloadUploadTotals];
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

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
	tableView.rowHeight = [[self.tableView dequeueReusableCellWithIdentifier:[FileHandler.sharedInstance settingsValueForKey:@"cell"]] frame].size.height;
}

- (IBAction)addTorrentPopup:(id)sender
{
	UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Open URL", @"Search via Queries", @"Scan QR Code", nil];
	alert.alertViewStyle = UIAlertViewStylePlainTextInput;
	[alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (alertView.alertViewStyle == UIAlertViewStylePlainTextInput)
	{
		[[alertView textFieldAtIndex:0] resignFirstResponder];
		NSString * text = [[alertView textFieldAtIndex:0] text];
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
				[self performSegueWithIdentifier:@"query" sender:nil];
				break;
			}
			case 3:
			{
				if (([[UIDevice.currentDevice.systemVersion componentsSeparatedByString:@"."].firstObject integerValue] >= 7))
				{
					[self performSegueWithIdentifier:@"scan" sender:nil];
				}
				else
				{
					[[UIAlertView.alloc initWithTitle:@"Unsupported Feature" message:@"QR code scanning is not supported on devices running a build earlier than 7.0" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
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
	self.sortBySheet = [UIActionSheet.alloc initWithTitle:@"Sort By" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
	for (NSString * string in self.sortByDictionary.allKeys)
	{
		[self.sortBySheet addButtonWithTitle:string];
	}
	[self.sortBySheet addButtonWithTitle:@"Cancel"];
	self.sortBySheet.cancelButtonIndex = self.sortByDictionary.count;
	[self.sortBySheet showFromToolbar:self.navigationController.toolbar];
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
				NSString * hashString = [self.sortedKeys objectAtIndex:actionSheet.tag][@"hash"];
				[NSNotificationCenter.defaultCenter postNotificationName:@"cancel_refresh" object:nil];
				[TorrentDelegate.sharedInstance.currentlySelectedClient addTemporaryDeletedJob:8 forKey:hashString];
				[TorrentDelegate.sharedInstance.currentlySelectedClient removeTorrent:hashString removeData:buttonIndex == 0];
				self.shouldRefresh = NO;
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{
					self.shouldRefresh = YES;
				});
				[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:actionSheet.tag inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
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
	if ([[TorrentDelegate.sharedInstance.currentlySelectedClient getUserFriendlyAppendedURL] length])
	{
		SVModalWebViewController *webViewController = [SVModalWebViewController.alloc initWithAddress:TorrentDelegate.sharedInstance.currentlySelectedClient.getUserFriendlyAppendedURL];
		[self presentViewController:webViewController animated:YES completion:nil];
	}
}

- (void)sortArray:(NSMutableArray *)array
{
	NSInteger sortBy = [self.sortByDictionary[[FileHandler.sharedInstance settingsValueForKey:@"sort_by"]] integerValue];
	switch (sortBy)
	{
		case COMPLETED:
		{
			[array sortUsingComparator: (NSComparator)^(NSDictionary *a, NSDictionary *b){
				NSComparisonResult res = [b[@"progress"] compare:a[@"progress"]];
				if (res != NSOrderedSame)
				{
					return res;
				}
				return [a[@"name"] compare:b[@"name"]];
			}];
			break;
		}

		case INCOMPLETE:
		{
			[array sortUsingComparator: (NSComparator)^(NSDictionary *a, NSDictionary *b){
				NSComparisonResult res = [a[@"progress"] compare:b[@"progress"]];
				if (res != NSOrderedSame)
				{
					return res;
				}
				return [a[@"name"] compare:b[@"name"]];
			}];
			break;
		}
		case DOWNLOAD_SPEED:
		{
			[array sortUsingComparator:(NSComparator)^(NSDictionary *a, NSDictionary *b){
				NSComparisonResult res = [b[@"rawDownloadSpeed"] compare:a[@"rawDownloadSpeed"]];
				if (res != NSOrderedSame)
				{
					return res;
				}
				return [a[@"name"] compare:b[@"name"]];
			}];
			break;
		}
		case UPLOAD_SPEED:
		{
			[array sortUsingComparator:(NSComparator)^(NSDictionary *a, NSDictionary *b){
				NSComparisonResult res = [b[@"rawUploadSpeed"] compare:a[@"rawUploadSpeed"]];
				if (res != NSOrderedSame)
				{
					return res;
				}
				return [a[@"name"] compare:b[@"name"]];
			}];
			break;
		}
		case ACTIVE:
		{
			[array sortUsingComparator:(NSComparator)^(NSDictionary *a, NSDictionary *b){
				if ([a[@"rawUploadSpeed"] integerValue] || [a[@"rawDownloadSpeed"] integerValue])
				{
					if (!([b[@"rawUploadSpeed"] integerValue] || [b[@"rawDownloadSpeed"] integerValue]))
					{
						return NSOrderedAscending;
					}
				}
				else if ([b[@"rawUploadSpeed"] integerValue] || [b[@"rawDownloadSpeed"] integerValue])
				{
					return NSOrderedDescending;
				}
				return [a[@"name"] compare:b[@"name"]];
			}];
			break;
		}
		case DOWNLOADING:
		case SEEDING:
		case PAUSED:
		{
			[array sortUsingComparator:(NSComparator)^(NSDictionary *a, NSDictionary *b){
				if ([self.sortByDictionary[a[@"status"]] integerValue] == sortBy)
				{
					if (!([self.sortByDictionary[b[@"status"]] integerValue] == sortBy))
					{
						return NSOrderedAscending;
					}
				}
				else if ([self.sortByDictionary[b[@"status"]] integerValue] == sortBy)
				{
					return NSOrderedDescending;
				}
				return [a[@"name"] compare:b[@"name"]];
			}];
			break;
		}
		default:
		case NAME:
		{
			[array sortUsingComparator: (NSComparator)^(NSDictionary *a, NSDictionary *b){
				return [a[@"name"] compare:b[@"name"]];
			}];
			break;
		}
		case SIZE:
		{
			[array sortUsingComparator:(NSComparator)^(NSDictionary *a, NSDictionary *b){
				NSComparisonResult res = [a[@"size"] compare:b[@"size"]];
				if (res != NSOrderedSame)
				{
					return res;
				}
				return [a[@"name"] compare:b[@"name"]];
			}];
			break;
		}
		case RATIO:
		{
			[array sortUsingComparator:(NSComparator)^(NSDictionary *a, NSDictionary *b){
				NSComparisonResult res = [b[@"ratio"] compare:a[@"ratio"]];
				if (res != NSOrderedSame)
				{
					return res;
				}
				return [a[@"name"] compare:b[@"name"]];
			}];
			break;
		}
		case DATE:
		{
			[array sortUsingComparator:(NSComparator)^(NSDictionary *a, NSDictionary *b){
				NSComparisonResult res = [a[@"dateAdded"] compare:b[@"dateAdded"]];
				if (res != NSOrderedSame)
				{
					return res;
				}
				return [a[@"name"] compare:b[@"name"]];
			}];
			break;
		}
	}
}

- (void)createDownloadUploadTotals
{
	NSUInteger uploadSpeed = 0, downloadSpeed = 0;
	if (!self.sortedKeys.count)
	{
		self.navigationItem.rightBarButtonItem = nil;
		return;
	}
	for (NSDictionary * dict in TorrentDelegate.sharedInstance.currentlySelectedClient.getJobsDict.allValues)
	{
		if (dict[@"rawUploadSpeed"] && dict[@"rawDownloadSpeed"])
		{
			uploadSpeed += [dict[@"rawUploadSpeed"] integerValue];
			downloadSpeed += [dict[@"rawDownloadSpeed"] integerValue];
		}
		else
		{
			self.navigationItem.rightBarButtonItem = nil;
			return;
		}
	}

	unsigned height = 11;
	UIView * newView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, height * 2)];
	newView.backgroundColor = [UIColor clearColor];

	UIFont * font = [UIFont fontWithName:@"Arial" size:height];

	UILabel * upload = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, height)];
	UILabel * download = [[UILabel alloc] initWithFrame:CGRectMake(0, height, 80, height)];

	if ([[UIDevice.currentDevice.systemVersion componentsSeparatedByString:@"."].firstObject integerValue] < 7)
	{
		upload.textColor = [UIColor whiteColor];
		download.textColor = [UIColor whiteColor];
	}

	upload.font = font;
	upload.text = [NSString stringWithFormat:@"↑ %@", @(uploadSpeed).transferRateString];
	upload.backgroundColor = UIColor.clearColor;
	download.font = font;
	download.text = [NSString stringWithFormat:@"↓ %@", @(downloadSpeed).transferRateString];
	download.backgroundColor = UIColor.clearColor;
	[newView addSubview:upload];
	[newView addSubview:download];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:newView];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	NSMutableArray *dictValues = [TorrentDelegate.sharedInstance.currentlySelectedClient.getJobsDict.allValues mutableCopy];
	[self sortArray:dictValues];
	self.sortedKeys = dictValues;
	
	return 1;
}

- (void)addProgressViewToCell:(TorrentJobCheckerCell *)cell withJob:(NSDictionary *)currentJob
{
	NSInteger tag = -(1 << 8);
	if (![[cell viewWithTag:tag].class isEqual:UIView.class])
	{
		UIView * view = [UIView.alloc initWithFrame:cell.frame];
		view.tag = tag;
		[cell insertSubview:view atIndex:0];
	}

	UIView * progressView = [cell viewWithTag:tag];
	CGRect frame = progressView.frame;
	double completeValue = [[[TorrentDelegate.sharedInstance.currentlySelectedClient class] completeNumber] doubleValue];
	frame.size.width = cell.frame.size.width * (completeValue ? [currentJob[@"progress"] doubleValue] / completeValue : 0);
	progressView.frame = frame;

	if ([currentJob[@"status"] isEqualToString:@"Seeding"])
	{
		progressView.backgroundColor = [UIColor colorWithRed:0 green:1 blue:.4 alpha:.3];
	}
	else if ([currentJob[@"status"] isEqualToString:@"Downloading"])
	{
		progressView.backgroundColor = [UIColor colorWithRed:0 green:.478 blue:1 alpha:.3];
	}
	else
	{
		progressView.backgroundColor = [UIColor colorWithRed:.85 green:.85 blue:.85 alpha:.5];
	}

	[progressView setNeedsDisplay];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *CellIdentifier = [FileHandler.sharedInstance settingsValueForKey:@"cell"];
	TorrentJobCheckerCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if ([cell.subviews.firstObject isKindOfClass:UIScrollView.class])
	{
		[cell.subviews.firstObject setDelegate:self];
	}
	NSDictionary * currentJob = nil;
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
		currentJob = self.filteredArray[indexPath.row];
    }
	else
	{
		currentJob = self.sortedKeys[indexPath.row];
	}

	cell.name.text = currentJob[@"name"];
	cell.hashString = currentJob[@"hash"];
	cell.currentStatus.text = currentJob[@"status"];
	
	if ([CellIdentifier characterAtIndex:0] == 'F')
	{
		[self addProgressViewToCell:cell withJob:currentJob];
	}
	else
	{
		double completeValue = [[[TorrentDelegate.sharedInstance.currentlySelectedClient class] completeNumber] doubleValue];
		cell.percentBar.progress = completeValue ? [currentJob[@"progress"] doubleValue] / completeValue : 0;
	}

	if ([currentJob[@"ETA"] length] && [currentJob[@"progress"] doubleValue] != [[TorrentDelegate.sharedInstance.currentlySelectedClient.class completeNumber] doubleValue])
	{
		cell.ETA.text = [NSString stringWithFormat:@"ETA: %@", currentJob[@"ETA"]];
	}
	else if (currentJob[@"ratio"])
	{
		cell.ETA.text = [NSString stringWithFormat:@"Ratio: %.3f", [currentJob[@"ratio"] doubleValue]];
	}
	else
	{
		cell.ETA.text = @"";
	}
	if ([CellIdentifier characterAtIndex:0] == 'P')
	{
		cell.downloadSpeed.text = [NSString stringWithFormat:@"↓ %@", currentJob[@"downloadSpeed"]];
	}
	else
	{
		cell.downloadSpeed.text = [NSString stringWithFormat:@"%@ ↓", currentJob[@"downloadSpeed"]];
	}

	if ([currentJob[@"status"] isEqualToString:@"Seeding"])
	{
		cell.percentBar.progressTintColor = [UIColor colorWithRed:0 green:1 blue:.4 alpha:1];
	}
	else if ([currentJob[@"status"] isEqualToString:@"Downloading"])
	{
		cell.percentBar.progressTintColor = [UIColor colorWithRed:0 green:.478 blue:1 alpha:1];
	}
	else
	{
		cell.percentBar.progressTintColor = [UIColor darkGrayColor];
	}

	cell.uploadSpeed.text = [NSString stringWithFormat:@"↑ %@", currentJob[@"uploadSpeed"]];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	{
		UIFont * font = [UIFont fontWithName:@"Arial" size:10];
		cell.downloadSpeed.font = font;
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
		popupQuery = [[UIActionSheet alloc] initWithTitle:@"Also delete data?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete data" otherButtonTitles:@"Delete torrent", nil];
	}
	else
	{
		popupQuery = [[UIActionSheet alloc] initWithTitle:@"Are you sure?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete torrent" otherButtonTitles:nil];
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
	if (self.header)
	{

		if ([TorrentDelegate.sharedInstance.currentlySelectedClient isHostOnline])
		{
			self.header.backgroundColor = [UIColor colorWithRed:77/255. green:149/255. blue:197/255. alpha:0.85];
			self.header.text = @"Host Online";
		}
		else
		{
			self.header.backgroundColor = [UIColor colorWithRed:250/255. green:50/255. blue:50/255. alpha:0.85];
			self.header.text = @"Host Offline";
		}
	}
	else
	{
		self.header = [UILabel.alloc initWithFrame:CGRectMake(0, 0, [tableView frame].size.width, [self sizeForDevice])];
		self.header.backgroundColor = [UIColor colorWithRed:0 green:0.9 blue:.2 alpha:.85];
		self.header.textColor = [UIColor whiteColor];
		self.header.text = @"Attempting Connection";
		self.header.font = [UIFont fontWithName:@"Arial" size:self.sizeForDevice - 6];
		self.header.textAlignment = NSTextAlignmentCenter;
		self.header.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	}
	return self.header;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
		return self.filteredArray.count;
	}
    return [[[TorrentDelegate.sharedInstance.currentlySelectedClient getJobsDict] allKeys] count];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.destinationViewController isKindOfClass:TorrentDetailViewController.class])
	{
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

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
	cancelNextRefresh = NO;
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
	return [[[TorrentDelegate.sharedInstance.currentlySelectedClient getJobsDict] allKeys] count] ? YES : NO;
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    return YES;
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text scope:[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    return YES;
}

- (void)filterContentForSearchText:(NSString *)searchText scope:(NSString *)scope
{
	self.filteredArray = NSMutableArray.new;
	NSDictionary * jobs = [TorrentDelegate.sharedInstance.currentlySelectedClient getJobsDict];
	for (NSDictionary * job in jobs.allValues)
	{
		if ([[job[@"name"] lowercaseString] rangeOfString:[searchText lowercaseString]].location != NSNotFound)
		{
			[self.filteredArray addObject:job];
		}
	}
	[self sortArray:self.filteredArray];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	cancelNextRefresh = YES;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	cancelNextRefresh = YES;
}

@end
