//
//  FirstViewController.h
//  BarMagnet
//
//  Created by Carlo Tortorella on 4/06/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TorrentClient.h"
#import "TorrentDetailViewController.h"

@interface TorrentJobsTableViewController : UITableViewController
{
	BOOL cancelNextRefresh;
	TorrentDetailViewController * tdv;
	NSArray * sortedKeys;
	NSDictionary * jobsDict;
}

- (IBAction)openUI:(id)sender;
@end