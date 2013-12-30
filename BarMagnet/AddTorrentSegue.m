//
//  AddTorrentSegue.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 4/12/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "AddTorrentSegue.h"

@implementation AddTorrentSegue

- (void)perform
{
	UINavigationController * navigationController = [self.sourceViewController navigationController];
	[navigationController popViewControllerAnimated:YES];
	[navigationController presentViewController:self.destinationViewController animated:YES completion:nil];
}

@end
