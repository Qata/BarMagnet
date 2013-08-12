//
//  TorrentJobCheckerCell.h
//  BarMagnet
//
//  Created by Carlo Tortorella on 7/07/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TorrentJobCheckerCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel* name;
@property (nonatomic, strong) IBOutlet UIProgressView* percentBar;
@property (nonatomic, strong) IBOutlet UILabel* downloadSpeed;
@property (nonatomic, strong) IBOutlet UILabel* uploadSpeed;
@property (nonatomic, strong) IBOutlet UILabel* currentStatus;
@property (nonatomic, strong) IBOutlet UILabel* ETA;

@end
