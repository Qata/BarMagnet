//
//  QueryCell.h
//  BarMagnet
//
//  Created by Carlo Tortorella on 24/01/2014.
//  Copyright (c) 2014 Carlo Tortorella. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QueryCell : UITableViewCell
@property (nonatomic, strong) IBOutlet UILabel * name;
@property (nonatomic, strong) IBOutlet UITextField * queryField;
@end