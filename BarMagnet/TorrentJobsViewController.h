//
//  TorrentJobsViewController.h
//  BarMagnet
//
//  Created by Carlo Tortorella on 29/06/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TorrentJobsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
	UIView * headerView;
	NSArray * sortedKeys;
	NSDictionary * jobsDict;
}
@end
