//
//  AddQueryTableViewController.h
//  BarMagnet
//
//  Created by Charlotte Tortorella on 24/01/2014.
//  Copyright (c) 2014 Charlotte Tortorella. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddQueryTableViewController : UITableViewController <UITextFieldDelegate>
@property(strong, nonatomic) NSDictionary *queryDictionary;
@property(strong, nonatomic) IBOutlet UITextField *name;
@property(strong, nonatomic) IBOutlet UITextField *URL;
@property(strong, nonatomic) IBOutlet UISwitch *usesQuery;
@end
