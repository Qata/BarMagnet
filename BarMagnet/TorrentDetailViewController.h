//
//  TorrentDetailViewController.h
//  BarMagnet
//
//  Created by Carlo Tortorella on 9/07/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TorrentDetailViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
	NSArray * identifierArray;
	NSString * hashString;
	NSDictionary * hashDict;
	UITableView * torrentJobsView;
	UITableView * selfView;
}

- (void)setHash:(NSString *)hash;
- (void)setJobsView:(UITableView *)jobsView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *playPauseButton;

@end
