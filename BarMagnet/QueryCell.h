//
//  QueryCell.h
//  BarMagnet
//
//  Created by Carlo Tortorella on 24/01/2014.
//  Copyright (c) 2014 Carlo Tortorella. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITextField+UniqueString.h"

@interface QueryCell : UITableViewCell
@property (nonatomic, strong) IBOutlet UILabel * name;
@property (nonatomic, strong) IBOutlet UITextField_UniqueString * queryField;
@property (nonatomic, strong) NSDictionary * queryDictionary;
@end