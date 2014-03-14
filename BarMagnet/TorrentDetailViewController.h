//
//  TorrentDetailViewController.h
//  BarMagnet
//
//  Created by Carlo Tortorella on 9/07/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TorrentDetailViewController : UITableViewController
{
	NSDictionary * hashDict;
	UITableView * torrentJobsView;
	UITableView * selfView;
}

@property (strong, nonatomic) NSString * hashString;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *playPauseButton;

@end
