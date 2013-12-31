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

@interface FirstViewController : UIViewController
{
	BOOL cancelNextRefresh;
	TorrentDetailViewController * tdv;
}

- (IBAction)openUI:(id)sender;

@property (strong, nonatomic) IBOutlet UITableView *torrentJobsTableView;

@end