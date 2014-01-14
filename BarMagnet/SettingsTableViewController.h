//
//  SettingsTableViewController.h
//  BarMagnet
//
//  Created by Carlo Tortorella on 4/06/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StaticDataTableViewController.h"

@interface SettingsTableViewController : StaticDataTableViewController  <UITextFieldDelegate, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UIPickerView *pickerView;
@property (strong, nonatomic) IBOutlet UITextField *hostnameField;
@property (strong, nonatomic) IBOutlet UITextField *portField;
@property (strong, nonatomic) IBOutlet UITextField *usernameField;
@property (strong, nonatomic) IBOutlet UITextField *passwordField;
@property (strong, nonatomic) IBOutlet UISegmentedControl *useSSLSegmentedControl;
@property (strong, nonatomic) IBOutlet UITextField *queryFormatField;
@property (strong, nonatomic) IBOutlet UITextField *torrentSiteField;

@property (strong, nonatomic) IBOutlet UITextField *relativePathField;
@property (strong, nonatomic) IBOutlet UITextField *directoryField;
@property (strong, nonatomic) IBOutlet UITextField *labelField;

@property (strong, nonatomic) IBOutlet UITableViewCell *relativePathCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *directoryCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *labelCell;

@end
