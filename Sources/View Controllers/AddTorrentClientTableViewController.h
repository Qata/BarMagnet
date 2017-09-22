//
//  SettingsTableViewController.h
//  BarMagnet
//
//  Created by Charlotte Tortorella on 4/06/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#import "StaticDataTableViewController.h"
#import <UIKit/UIKit.h>

@interface AddTorrentClientTableViewController : StaticDataTableViewController <UITextFieldDelegate, UITableViewDelegate>

@property(strong, nonatomic) IBOutlet UIPickerView *pickerView;
@property(strong, nonatomic) IBOutlet UITextField *nameField;
@property(strong, nonatomic) IBOutlet UITextField *hostnameField;
@property(strong, nonatomic) IBOutlet UITextField *portField;
@property(strong, nonatomic) IBOutlet UITextField *usernameField;
@property(strong, nonatomic) IBOutlet UITextField *passwordField;
@property(strong, nonatomic) IBOutlet UISegmentedControl *useSSLSegmentedControl;

@property(strong, nonatomic) IBOutlet UITextField *relativePathField;
@property(strong, nonatomic) IBOutlet UITextField *directoryField;
@property(strong, nonatomic) IBOutlet UITextField *labelField;

@property(strong, nonatomic) IBOutlet UITableViewCell *relativePathCell;
@property(strong, nonatomic) IBOutlet UITableViewCell *directoryCell;
@property(strong, nonatomic) IBOutlet UITableViewCell *labelCell;
@property(strong, nonatomic) IBOutlet UITableViewCell *useSSLCell;
@property(strong, nonatomic) IBOutlet UITableViewCell *portCell;
@property(strong, nonatomic) IBOutlet UITableViewCell *seedStuffCell;
@property(nonatomic, strong) NSDictionary *clientDictionary;

@end
