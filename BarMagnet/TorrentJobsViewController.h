//
//  TorrentJobsViewController.h
//  BarMagnet
//
//  Created by Carlo Tortorella on 29/06/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FirstViewController.h"

@interface TorrentJobsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate>
{
	UIView * headerView;
	NSArray * sortedKeys;
	NSDictionary * jobsDict;
}
@property (weak, nonatomic) IBOutlet FirstViewController *viewController;
@end