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

@interface AddTorrentClientTableViewController () <UIPickerViewDataSource, UIPickerViewDelegate>
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

- (TorrentClient *)getCurrentlySelectedClient
{
    NSArray * delegateArray = [TorrentDelegate.sharedInstance.torrentDelegates.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    return TorrentDelegate.sharedInstance.torrentDelegates[delegateArray[[self.pickerView selectedRowInComponent:0]]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	if (!self.clientDictionary)
	{
		self.navigationItem.leftBarButtonItem = [UIBarButtonItem.alloc initWithTitle:@"Cancel" style:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
	}
	self.navigationItem.rightBarButtonItem = [UIBarButtonItem.alloc initWithTitle:@"Save" style:UIBarButtonSystemItemSave target:self action:@selector(save)];
	self.cellNames = @[@"Pretty", @"Compact", @"Fast"];
    self.sortedArray = [[TorrentDelegate.sharedInstance.torrentDelegates allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    [self.pickerView selectRow:[self.sortedArray indexOfObject:@"Transmission"] inComponent:0 animated:NO];
	self.selectedClient = @"Transmission";
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	for (UITextField * field in self.fields = @[self.hostnameField, self.usernameField, self.passwordField, self.portField, self.directoryField, self.labelField, self.relativePathField])
	{
		field.delegate = self;
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self hideCells];
}

- (void)hideCells
{
	TorrentClient * torrentDelegate = TorrentDelegate.sharedInstance.torrentDelegates[self.selectedClient];
	[self cell:self.labelCell setHidden:![[[torrentDelegate class] name] isEqual:@"ruTorrent"]];
	[self cell:self.directoryCell setHidden:!torrentDelegate.supportsDirectoryChoice];
	[self cell:[self relativePathCell] setHidden:!torrentDelegate.supportsRelativePath];
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
	if (self.hostnameField.text.length && self.portField.text.length && self.nameField.text.length)
	{
		NSMutableArray * array = [[NSUserDefaults.standardUserDefaults objectForKey:@"clients"] mutableCopy];
		if (!array)
		{
			array = NSMutableArray.new;
		}
		NSDictionary * object = @{@"name":self.nameField.text, @"type":self.selectedClient, @"url":[self cleanURL:self.hostnameField.text], @"port":self.portField.text, @"username":self.usernameField.text, @"password":self.passwordField.text, @"use_ssl":@(self.useSSLSegmentedControl.selectedSegmentIndex), @"relative_path":self.relativePathField.text, @"directory":self.directoryField.text, @"label":self.labelField.text};
		if (self.clientDictionary)
		{
			[array replaceObjectAtIndex:[[NSUserDefaults.standardUserDefaults objectForKey:@"clients"] indexOfObject:self.clientDictionary] withObject:object];
		}
		else
		{
			BOOL containsName = NO;
			for (NSDictionary * dict in array)
			{
				if ([dict[@"name"] isEqualToString:self.nameField.text])
				{
					containsName = YES;
				}
			}
			if (!containsName)
			{
				[array addObject:object];
			}
			else
			{
				[[UIAlertView.alloc initWithTitle:@"Error" message:[NSString stringWithFormat:@"You already have a client named %@", self.nameField.text] delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
				return;
			}
		}
		[NSUserDefaults.standardUserDefaults setObject:array forKey:@"clients"];
		[self dismiss];
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
