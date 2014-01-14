//
//  SettingsTableViewController.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 4/06/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "FileHandler.h"
#import "TorrentDelegateConfig.h"
#import "TorrentDelegate.h"
#import "TorrentClient.h"

@interface SettingsTableViewController () <UIPickerViewDataSource, UIPickerViewDelegate>
@property (nonatomic, strong) NSString * serverType;
@property (nonatomic, strong) NSArray * sortedArray;
@end

@implementation SettingsTableViewController

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (NSString *)cleanURL:(NSString *)url
{
	//A URL should look like this: "192.168.0.1"
	//This function is to make sure it doesn't look like this: "192.160.0.1/transmission/"
	url = [[url stringByReplacingOccurrencesOfString:@"http://" withString:@""] stringByReplacingOccurrencesOfString:@"https://" withString:@""];
	NSString * subString = [url getStringBetween:@"/" andString:@"/"];
	if ([subString length])
	{
		if ([url rangeOfString:[NSString stringWithFormat:@"/%@/", subString]].location != NSNotFound)
		{
			return [url stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"/%@/", subString] withString:@""];
		}
		else if ([url rangeOfString:[NSString stringWithFormat:@"/%@", subString]].location != NSNotFound)
		{
			return [url stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"/%@", subString] withString:@""];
		}
	}
	else
	{
		return [url stringByReplacingOccurrencesOfString:@"/" withString:@""];
	}
	return url;
}

- (TorrentClient *)getCurrentlySelectedClient
{
    NSArray * delegateArray = [[[[TorrentDelegateConfig sharedInstance] torrentDelegates] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    return [[[TorrentDelegateConfig sharedInstance] torrentDelegates] objectForKey:[delegateArray objectAtIndex:[[self pickerView] selectedRowInComponent:0]]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideCells:) name:@"hideCells" object:nil];
    [[self hostnameField] setText:[[FileHandler.sharedInstance webDataValueForKey:@"url" andDict:nil] orSome:@""]];
    [[self usernameField] setText:[[FileHandler.sharedInstance webDataValueForKey:@"username" andDict:nil] orSome:@""]];
    [[self passwordField] setText:[[FileHandler.sharedInstance webDataValueForKey:@"password" andDict:nil] orSome:@""]];
    [[self portField] setText:[[FileHandler.sharedInstance webDataValueForKey:@"port" andDict:nil] orSome:@"80"]];
	[[self relativePathField] setText:[[FileHandler.sharedInstance webDataValueForKey:@"relative_path" andDict:nil] orSome:@""]];
	[[self directoryField] setText:[[FileHandler.sharedInstance webDataValueForKey:@"directory" andDict:nil] orSome:@""]];
	[[self labelField] setText:[[FileHandler.sharedInstance webDataValueForKey:@"label" andDict:nil] orSome:@""]];
	[[self queryFormatField] setText:[FileHandler.sharedInstance settingsValueForKey:@"query_format"]];
	[[self torrentSiteField] setText:[FileHandler.sharedInstance settingsValueForKey:@"preferred_torrent_site"]];
	[[self useSSLSegmentedControl] setSelectedSegmentIndex:[[[FileHandler.sharedInstance webDataValueForKey:@"use_ssl" andDict:nil] orSome:@NO] intValue]];
    self.serverType = [FileHandler.sharedInstance settingsValueForKey:@"server_type"];
    self.sortedArray = [[[[TorrentDelegateConfig sharedInstance] torrentDelegates] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    [self.pickerView selectRow:[self.sortedArray indexOfObject:self.serverType] inComponent:0 animated:NO];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self hideCells:[NSNotification notificationWithName:@"hideCells" object:nil userInfo:@{@"torrentDelegate":[[TorrentDelegate sharedInstance] currentlySelectedClient]}]];
}

- (IBAction)synchronizeData:(id)sender
{
    [FileHandler.sharedInstance setSettingsValue:[self.sortedArray objectAtIndex:[[self pickerView] selectedRowInComponent:0]] forKey:@"server_type"];
    [FileHandler.sharedInstance setWebDataValue:[self cleanURL:self.hostnameField.text] forKey:@"url" andDict:nil];
    [FileHandler.sharedInstance setWebDataValue:self.usernameField.text forKey:@"username" andDict:nil];
    [FileHandler.sharedInstance setWebDataValue:self.passwordField.text forKey:@"password" andDict:nil];
    [FileHandler.sharedInstance setWebDataValue:self.portField.text forKey:@"port" andDict:nil];
    [FileHandler.sharedInstance setWebDataValue:self.directoryField.text forKey:@"directory" andDict:nil];
    [FileHandler.sharedInstance setWebDataValue:self.labelField.text forKey:@"label" andDict:nil];
    [FileHandler.sharedInstance setWebDataValue:self.relativePathField.text forKey:@"relative_path" andDict:nil];
	[FileHandler.sharedInstance setWebDataValue:@([[self useSSLSegmentedControl] selectedSegmentIndex]) forKey:@"use_ssl" andDict:nil];
	[FileHandler.sharedInstance setSettingsValue:[self.queryFormatField.text stringByReplacingOccurrencesOfString:@"http://" withString:@""] forKey:@"query_format"];
	[FileHandler.sharedInstance setSettingsValue:[self.torrentSiteField.text stringByReplacingOccurrencesOfString:@"http://" withString:@""] forKey:@"preferred_torrent_site"];
	
}

- (void)hideCells:(NSNotification *)notification
{
	TorrentClient * torrentDelegate = [notification userInfo][@"torrentDelegate"];

	[self cell:self.labelCell setHidden:![[[torrentDelegate class] name] isEqual:@"ruTorrent"]];
	[self cell:self.directoryCell setHidden:!torrentDelegate.supportsDirectoryChoice];

	[self cell:[self relativePathCell] setHidden:!torrentDelegate.shouldShowSpecificsButton];
	[self reloadDataAnimated:YES];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.sortedArray count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return self.sortedArray[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	[[[TorrentDelegate sharedInstance] currentlySelectedClient] becameIdle];
    [FileHandler.sharedInstance setSettingsValue:[self.sortedArray objectAtIndex:[[self pickerView] selectedRowInComponent:0]] forKey:@"server_type"];
    [[self hostnameField] setText:[[FileHandler.sharedInstance webDataValueForKey:@"url" andDict:[self.sortedArray objectAtIndex:row]] orSome:@""]];
    [[self usernameField] setText:[[FileHandler.sharedInstance webDataValueForKey:@"username" andDict:[self.sortedArray objectAtIndex:row]] orSome:@""]];
    [[self passwordField] setText:[[FileHandler.sharedInstance webDataValueForKey:@"password" andDict:[self.sortedArray objectAtIndex:row]] orSome:@""]];
    [[self portField] setText:[[FileHandler.sharedInstance webDataValueForKey:@"port" andDict:[self.sortedArray objectAtIndex:row]] orSome:@"80"]];
	[[self directoryField] setText:[[FileHandler.sharedInstance webDataValueForKey:@"directory" andDict:[self.sortedArray objectAtIndex:row]] orSome:@""]];
	[[self labelField] setText:[[FileHandler.sharedInstance webDataValueForKey:@"label" andDict:[self.sortedArray objectAtIndex:row]] orSome:@""]];
	[[self relativePathField] setText:[[FileHandler.sharedInstance webDataValueForKey:@"relative_path" andDict:[self.sortedArray objectAtIndex:row]] orSome:@""]];
	[[self queryFormatField] setText:[FileHandler.sharedInstance settingsValueForKey:@"query_format"]];
	[[self torrentSiteField] setText:[FileHandler.sharedInstance settingsValueForKey:@"preferred_torrent_site"]];
	[[self useSSLSegmentedControl] setSelectedSegmentIndex:[[[FileHandler.sharedInstance webDataValueForKey:@"use_ssl" andDict:[self.sortedArray objectAtIndex:row]] orSome:@0] intValue]];
	[[[TorrentDelegate sharedInstance] currentlySelectedClient] becameActive];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"hideCells" object:nil userInfo:@{@"torrentDelegate":[[TorrentDelegateConfig sharedInstance] torrentDelegates][[self.sortedArray objectAtIndex:row]]}];

	[[[TorrentDelegate sharedInstance] currentlySelectedClient] setJobsData:nil];
	[[[TorrentDelegate sharedInstance] currentlySelectedClient] handleTorrentJobs];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"update_torrent_jobs_table" object:nil];
}

@end
