//
//  SettingsTableViewController.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 4/06/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "FileHandler.h"
#import "TorrentJobChecker.h"
#import "TorrentDelegate.h"
#import "TorrentClient.h"

@interface SettingsTableViewController () <UIPickerViewDataSource, UIPickerViewDelegate>
@property (nonatomic, strong) NSArray * cellNames;
@property (nonatomic, strong) NSArray * sortedArray;
@property (nonatomic, assign) BOOL shouldRefresh;
@property (nonatomic, strong) NSArray * fields;
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
    NSArray * delegateArray = [[[[TorrentDelegate sharedInstance] torrentDelegates] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    return [[[TorrentDelegate sharedInstance] torrentDelegates] objectForKey:[delegateArray objectAtIndex:[[self pickerView] selectedRowInComponent:0]]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.cellNames = @[@"Pretty", @"Compact", @"Fast"];
    self.sortedArray = [[[[TorrentDelegate sharedInstance] torrentDelegates] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    [self.pickerView selectRow:[self.sortedArray indexOfObject:[FileHandler.sharedInstance settingsValueForKey:@"server_type"]] inComponent:0 animated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	for (UITextField * field in self.fields = @[self.hostnameField, self.usernameField, self.passwordField, self.portField, self.directoryField, self.labelField, self.relativePathField, self.queryFormatField, self.torrentSiteField])
	{
		field.delegate = self;
		[field addTarget:self action:@selector(synchronizeData:) forControlEvents:UIControlEventEditingDidEnd];
	}
	[self.torrentCellTypeSegmentedControl addTarget:self action:@selector(synchronizeData:) forControlEvents:UIControlEventValueChanged];
	[self.useSSLSegmentedControl addTarget:self action:@selector(synchronizeData:) forControlEvents:UIControlEventValueChanged];

	[self pickerView:self.pickerView didSelectRow:[self.sortedArray indexOfObject:[FileHandler.sharedInstance settingsValueForKey:@"server_type"]] inComponent:0];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self hideCells];
}

- (void)viewWillDisappear:(BOOL)animated
{
	for (UITextField * field in self.fields)
	{
		[field resignFirstResponder];
	}
	[TorrentJobChecker.sharedInstance performSelectorInBackground:@selector(credentialsCheckInvocation) withObject:nil];
	[super viewWillDisappear:animated];
}

- (IBAction)synchronizeData:(id)sender
{
    [FileHandler.sharedInstance setSettingsValue:self.sortedArray[[[self pickerView] selectedRowInComponent:0]] forKey:@"server_type"];
    [FileHandler.sharedInstance setWebDataValue:[self cleanURL:self.hostnameField.text] forKey:@"url" andDict:nil];
    [FileHandler.sharedInstance setWebDataValue:self.usernameField.text forKey:@"username" andDict:nil];
    [FileHandler.sharedInstance setWebDataValue:self.passwordField.text forKey:@"password" andDict:nil];
    [FileHandler.sharedInstance setWebDataValue:self.portField.text forKey:@"port" andDict:nil];
    [FileHandler.sharedInstance setWebDataValue:self.directoryField.text forKey:@"directory" andDict:nil];
    [FileHandler.sharedInstance setWebDataValue:self.labelField.text forKey:@"label" andDict:nil];
    [FileHandler.sharedInstance setWebDataValue:self.relativePathField.text forKey:@"relative_path" andDict:nil];
	[FileHandler.sharedInstance setWebDataValue:@(self.useSSLSegmentedControl.selectedSegmentIndex) forKey:@"use_ssl" andDict:nil];
	[FileHandler.sharedInstance setSettingsValue:self.cellNames[self.torrentCellTypeSegmentedControl.selectedSegmentIndex] forKey:@"cell"];
	[FileHandler.sharedInstance setSettingsValue:[self.queryFormatField.text stringByReplacingOccurrencesOfString:@"http://" withString:@""] forKey:@"query_format"];
	[FileHandler.sharedInstance setSettingsValue:[self.torrentSiteField.text stringByReplacingOccurrencesOfString:@"http://" withString:@""] forKey:@"preferred_torrent_site"];

	if (self.useSSLSegmentedControl.selectedSegmentIndex)
	{
		[NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[self cleanURL:self.hostnameField.text]];
	}
}

- (void)hideCells
{
	TorrentClient * torrentDelegate = TorrentDelegate.sharedInstance.currentlySelectedClient;

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

- (BOOL)shouldRefresh
{
	BOOL retVal = _shouldRefresh;
	_shouldRefresh = YES;
	return retVal;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	[TorrentDelegate.sharedInstance.currentlySelectedClient becameIdle];
    [FileHandler.sharedInstance setSettingsValue:self.sortedArray[[[self pickerView] selectedRowInComponent:0]] forKey:@"server_type"];
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
	[self.torrentCellTypeSegmentedControl setSelectedSegmentIndex:[self.cellNames indexOfObject:[FileHandler.sharedInstance settingsValueForKey:@"cell"]]];
	[TorrentDelegate.sharedInstance.currentlySelectedClient becameActive];
	[self hideCells];

	if (self.shouldRefresh)
	{
		[TorrentDelegate.sharedInstance.currentlySelectedClient setJobsData:nil];
		[TorrentDelegate.sharedInstance.currentlySelectedClient handleTorrentJobs];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"update_torrent_jobs_table" object:nil];
	}
}

@end
