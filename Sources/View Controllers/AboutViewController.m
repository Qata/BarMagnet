//
//  AboutViewController.m
//  BarMagnet
//
//  Created by Charlotte Tortorella on 31/12/2013.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#import "AboutViewController.h"
#import "SVModalWebViewController.h"

@implementation AboutViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.title = [NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleName"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

    if ([cell.textLabel.text isEqualToString:@"Version"]) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
                                                               [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
    }

    return cell;
}

@end
