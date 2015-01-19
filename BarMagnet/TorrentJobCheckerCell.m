//
//  TorrentJobCheckerCell.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 7/07/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "TorrentJobCheckerCell.h"
#import "TorrentJobsTableViewController.h"

@implementation TorrentJobCheckerCell

- (void)setSwipeOffset:(CGFloat) newOffset
{
	[super setSwipeOffset:newOffset];
	[self.table setShouldRefresh:newOffset == 0];
}

@end
