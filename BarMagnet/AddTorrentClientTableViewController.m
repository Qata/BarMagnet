//
//  SettingsTableViewController.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 4/06/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "AddTorrentClientTableViewController.h"
#import "FileHandler.h"
#import "TorrentJobChecker.h"
#import "TorrentDelegate.h"
#import "TorrentClient.h"
#import "ruTorrent.h"
#import "rTorrentXMLRPC.h"
#import "SeedStuffSeedbox.h"

@interface AddTorrentClientTableViewController () <UIPickerViewDataSource, UIPickerViewDelegate, UIAlertViewDelegate>
@property (nonatomic, strong) NSArray * cellNames;
@property (nonatomic, strong) NSArray * sortedArray;
@property (nonatomic, strong) NSArray * fields;
@property (nonatomic, strong) NSString * selectedClient;
@end

@implementation AddTorrentClientTableViewController

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (NSString *)cleanURL:(NSString *)url
{
	url = [[url stringByReplacingOccurrencesOfString:@"http://" withString:@""] stringByReplacingOccurrencesOfString:@"https://" withString:@""];
	if ([url rangeOfString:@"/"].location != NSNotFound)
	{
		return [url substringToIndex:[url rangeOfString:@"/"].location];
	}
	return url;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	if (!self.clientDictionary)
	{
		self.navigationItem.leftBarButtonItem = [UIBarButtonItem.alloc initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
	}
	else
	{
		self.title = @"Edit Client";
	}
	self.navigationItem.rightBarButtonItem = [UIBarButtonItem.alloc initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(save)];
	self.cellNames = @[@"Pretty", @"Compact", @"Fast"];
    self.sortedArray = [[TorrentDelegate.sharedInstance.torrentDelegates allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    [self.pickerView selectRow:[self.sortedArray indexOfObject:[SeedStuffSeedbox.class name]] inComponent:0 animated:NO];
	self.selectedClient = [SeedStuffSeedbox.class name];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.navigationController setToolbarHidden:NO animated:NO];
	
	if (self.clientDictionary)
	{
		if ([self.sortedArray containsObject:self.clientDictionary[@"type"]])
		{
			[self.pickerView selectRow:[self.sortedArray indexOfObject:self.clientDictionary[@"type"]] inComponent:0 animated:NO];
		}
		self.selectedClient = self.clientDictionary[@"type"];
		self.nameField.text = self.clientDictionary[@"name"];
		self.hostnameField.text = self.clientDictionary[@"url"];
		self.portField.text = self.clientDictionary[@"port"];
		self.usernameField.text = self.clientDictionary[@"username"];
		self.passwordField.text = self.clientDictionary[@"password"];
		self.useSSLSegmentedControl.selectedSegmentIndex = [self.clientDictionary[@"use_ssl"] boolValue];
		self.directoryField.text = self.clientDictionary[@"directory"];
		self.relativePathField.text = self.clientDictionary[@"relative_path"];
		self.labelField.text = self.clientDictionary[@"label"];
		[self cell:self.seedStuffCell setHidden:YES];
		[self reloadDataAnimated:NO];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self hideCells];
}

- (void)hideCells
{
	Class torrentDelegate = TorrentDelegate.sharedInstance.torrentDelegates[self.selectedClient];
	[self cell:self.portCell setHidden:[torrentDelegate isEqual:SeedStuffSeedbox.class]];
	[self cell:self.useSSLCell setHidden:[torrentDelegate isEqual:SeedStuffSeedbox.class]];
	[self cell:self.seedStuffCell setHidden:![torrentDelegate isEqual:SeedStuffSeedbox.class]];
	[self cell:self.labelCell setHidden:![torrentDelegate isEqual:ruTorrent.class]];
	[self cell:self.directoryCell setHidden:![torrentDelegate supportsDirectoryChoice]];
	[self cell:self.relativePathCell setHidden:![torrentDelegate supportsRelativePath]];
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
	self.selectedClient = self.sortedArray[row];
	[self hideCells];
}

- (void)save
{
	if (self.hostnameField.text.length && self.nameField.text.length)
	{
		if (!self.portField.text.length)
		{
			self.portField.text = [TorrentDelegate.sharedInstance.torrentDelegates[self.selectedClient] defaultPort];
		}
		NSMutableArray * array = [[NSUserDefaults.standardUserDefaults objectForKey:@"clients"] mutableCopy];
		if (!array)
		{
			array = NSMutableArray.new;
			[FileHandler.sharedInstance setSettingsValue:[[NSOption fromNil:self.nameField.text] orSome:@""] forKey:@"server_name"];
			[FileHandler.sharedInstance setSettingsValue:[[NSOption fromNil:self.selectedClient] orSome:@""] forKey:@"server_type"];
		}

		NSDictionary * object = @{@"name":[[NSOption fromNil:self.nameField.text] orSome:@""], @"type":[[NSOption fromNil:self.selectedClient] orSome:@""], @"url":[self cleanURL:[[NSOption fromNil:self.hostnameField.text] orSome:@""]], @"port":[[NSOption fromNil:self.portField.text] orSome:@""], @"username":[[NSOption fromNil:self.usernameField.text] orSome:@""], @"password":[[NSOption fromNil:self.passwordField.text] orSome:@""], @"use_ssl":@(self.useSSLSegmentedControl.selectedSegmentIndex), @"relative_path":[[NSOption fromNil:self.relativePathField.text] orSome:@""], @"directory":[[NSOption fromNil:self.directoryField.text] orSome:@""], @"label":[[NSOption fromNil:self.labelField.text] orSome:@""]};


		BOOL containsName = NO;
		for (NSDictionary * dict in array)
		{
			if ([dict[@"name"] isEqualToString:self.nameField.text] && ![dict isEqualToDictionary:self.clientDictionary])
			{
				containsName = YES;
			}
		}
		if (!containsName)
		{
			if (self.clientDictionary)
			{
				if ([[FileHandler.sharedInstance settingsValueForKey:@"server_name"] isEqualToString:self.clientDictionary[@"name"]])
				{
					[FileHandler.sharedInstance setSettingsValue:object[@"name"] forKey:@"server_name"];
					[FileHandler.sharedInstance setSettingsValue:object[@"type"] forKey:@"server_type"];
				}
				[array replaceObjectAtIndex:[[NSUserDefaults.standardUserDefaults objectForKey:@"clients"] indexOfObject:self.clientDictionary] withObject:object];
			}
			else
			{
				[array addObject:object];
			}
		}
		else
		{
			[[UIAlertView.alloc initWithTitle:@"Error" message:[NSString stringWithFormat:@"You already have a client named %@", self.nameField.text] delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
			return;
		}

		[NSUserDefaults.standardUserDefaults setObject:array forKey:@"clients"];
		[self dismiss];
	}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != alertView.cancelButtonIndex)
	{
		[UIApplication.sharedApplication openURL:[NSURL URLWithString:@"http://seedstuff.ca/aff.php?aff=250"]];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section)
	{
		[[UIAlertView.alloc initWithTitle:@"SeedStuff.ca" message:@"Seedstuff is a seedbox company who strives to be able to provide the best customer service and most reliable seedboxes at an affordable price while keeping a commitment to ensuring their customers personal privacy. " delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Visit Site", nil] show];
	}
}

- (void)dismiss
{
	if (self.clientDictionary)
	{
		[self.navigationController popViewControllerAnimated:YES];
	}
	else
	{
		[self dismissViewControllerAnimated:YES completion:nil];
	}
}

@end
