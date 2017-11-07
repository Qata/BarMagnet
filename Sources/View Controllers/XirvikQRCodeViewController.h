//
//  XirvikQRCodeViewController.h
//  BarMagnet
//
//  Created by Charlotte Tortorella on 2017-11-04.
//  Copyright © 2017 Charlotte Tortorella. All rights reserved.
//

#import "ScanQRCodeViewController.h"
#import "AddTorrentClientTableViewController.h"

@interface XirvikQRCodeViewController : ScanQRCodeViewController
@property(weak, nonatomic) AddTorrentClientTableViewController *delegate;
@end
