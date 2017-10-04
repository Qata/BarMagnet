//
//  TransferTotal.h
//  BarMagnet
//
//  Created by Charlotte Tortorella on 2017-10-03.
//  Copyright © 2017 Charlotte Tortorella. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface TransferTotal : UIView
@property (weak, nonatomic) IBOutlet UILabel *uploadSpeedLabel;
@property (weak, nonatomic) IBOutlet UILabel *downloadSpeedLabel;
@end
