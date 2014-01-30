//
//  TorrentJobCheckerCell.h
//  BarMagnet
//
//  Created by Carlo Tortorella on 7/07/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//
#import "UIFastProgressBar.h"
#import <UIKit/UIKit.h>

@interface TorrentJobCheckerCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel* name;
@property (nonatomic, strong) IBOutlet UIFastProgressBar* percentBar;
@property (nonatomic, strong) IBOutlet UILabel* downloadSpeed;
@property (nonatomic, strong) IBOutlet UILabel* uploadSpeed;
@property (nonatomic, strong) IBOutlet UILabel* currentStatus;
@property (nonatomic, strong) IBOutlet UILabel* ETA;
@property (nonatomic, strong) NSString * hashString;

@end
