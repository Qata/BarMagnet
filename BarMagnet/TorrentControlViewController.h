//
//  TorrentControlViewController.h
//  BarMagnet
//
//  Created by Carlo Tortorella on 14/07/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TorrentControlViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>
{
	NSArray * identifierArray;
	NSString * hashString;
	NSDictionary * hashDict;
	UITableView * torrentJobsView;
	UITableView * selfView;
}

- (void)setHash:(NSString *)hash;
- (void)setJobsView:(UITableView *)jobsView;

@end
