//
//  FirstViewController.h
//  BarMagnet
//
//  Created by Charlotte Tortorella on 4/06/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#import "TorrentClient.h"
#import "TorrentDetailViewController.h"
#import <UIKit/UIKit.h>

@interface TorrentJobsTableViewController : UITableViewController <UIViewControllerPreviewingDelegate> {
    BOOL cancelNextRefresh;
}

- (IBAction)openUI:(id)sender;
@property(nonatomic, assign) BOOL shouldRefresh;
@end
