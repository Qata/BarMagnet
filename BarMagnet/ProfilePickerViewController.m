//
//  ProfilePickerViewController.m
//  DALI Lighting
//
//  Created by Carlo Tortorella on 31/05/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "ProfilePickerViewController.h"
#import "TorrentDelegate.h"
#import "TorrentDelegateConfig.h"
#import "FileHandler.h"

@implementation ProfilePickerViewController

- (id)init
{
    if (self = [super init])
    {
        serverType = [[FileHandler sharedInstance] settingsValueForKey:@"server_type"];
        sortedArray = [[[[TorrentDelegateConfig sharedInstance] torrentDelegates] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    }
    return self;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [sortedArray count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return sortedArray[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	[[[TorrentDelegate sharedInstance] currentlySelectedClient] becameIdle];
    [[FileHandler sharedInstance] setSettingsValue:[sortedArray objectAtIndex:[[self pickerView] selectedRowInComponent:0]] forKey:@"server_type"];
    [[self hostnameField] setText:[[[FileHandler sharedInstance] webDataValueForKey:@"url" andDict:[sortedArray objectAtIndex:row]] orSome:@""]];
    [[self usernameField] setText:[[[FileHandler sharedInstance] webDataValueForKey:@"username" andDict:[sortedArray objectAtIndex:row]] orSome:@""]];
    [[self passwordField] setText:[[[FileHandler sharedInstance] webDataValueForKey:@"password" andDict:[sortedArray objectAtIndex:row]] orSome:@""]];
    [[self portField] setText:[[[FileHandler sharedInstance] webDataValueForKey:@"port" andDict:[sortedArray objectAtIndex:row]] orSome:@"80"]];
	[[self directoryField] setText:[[[FileHandler sharedInstance] webDataValueForKey:@"directory" andDict:[sortedArray objectAtIndex:row]] orSome:@""]];
	[[self labelField] setText:[[[FileHandler sharedInstance] webDataValueForKey:@"label" andDict:[sortedArray objectAtIndex:row]] orSome:@""]];
	[[self relativePathField] setText:[[[FileHandler sharedInstance] webDataValueForKey:@"relative_path" andDict:[sortedArray objectAtIndex:row]] orSome:@""]];
	[[self queryFormatField] setText:[[FileHandler sharedInstance] settingsValueForKey:@"query_format"]];
	[[self torrentSiteField] setText:[[FileHandler sharedInstance] settingsValueForKey:@"preferred_torrent_site"]];
	[[self useSSLSegmentedControl] setSelectedSegmentIndex:[[[[FileHandler sharedInstance] webDataValueForKey:@"use_ssl" andDict:[sortedArray objectAtIndex:row]] orSome:@0] intValue]];
	[[[TorrentDelegate sharedInstance] currentlySelectedClient] becameActive];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"hideCells" object:nil userInfo:@{@"torrentDelegate":[[TorrentDelegateConfig sharedInstance] torrentDelegates][[sortedArray objectAtIndex:row]]}];

	[[[TorrentDelegate sharedInstance] currentlySelectedClient] setJobsData:nil];
	[[[TorrentDelegate sharedInstance] currentlySelectedClient] handleTorrentJobs];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"update_torrent_jobs_table" object:nil];
}

@end