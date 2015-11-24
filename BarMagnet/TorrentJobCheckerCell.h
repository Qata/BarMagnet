//
//  TorrentJobCheckerCell.h
//  BarMagnet
//
//  Created by Charlotte Tortorella on 7/07/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//
#import "MGSwipeTableCell.h"
#import "MGSwipeButton.h"
#import "UIFastProgressBar.h"
#import <UIKit/UIKit.h>

@class TorrentJobsTableViewController;

@interface TorrentJobCheckerCell : MGSwipeTableCell

@property (nonatomic, strong) IBOutlet UILabel* name;
@property (nonatomic, strong) IBOutlet UIFastProgressBar* percentBar;
@property (nonatomic, strong) IBOutlet UILabel* downloadSpeed;
@property (nonatomic, strong) IBOutlet UILabel* uploadSpeed;
@property (nonatomic, strong) IBOutlet UILabel* currentStatus;
@property (nonatomic, strong) IBOutlet UILabel* ETA;
@property (nonatomic, strong) NSString * hashString;
@property (nonatomic, weak) TorrentJobsTableViewController * table;

@end
