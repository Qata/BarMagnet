//
//  ConfigurableButton.m
//  DALI Lighting
//
//  Created by Carlo Tortorella on 14/06/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "ConfigurableButton.h"
#import <QuartzCore/QuartzCore.h>

@implementation ConfigurableButton

- (void)awakeFromNib
{
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = 10;
    self.layer.backgroundColor = [[UIColor whiteColor] CGColor];
    self.layer.borderColor = [[UIColor blackColor] CGColor];
    self.layer.borderWidth = 1;

	[self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[self setTitleColor:[UIColor colorWithRed:0 green:0.4 blue:229./255. alpha:1] forState:UIControlStateHighlighted];
    //[self setHighlightedColor:];
}

- (void)setHighlightedColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context,[color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self setBackgroundImage:img forState:UIControlStateHighlighted];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    self.layer.backgroundColor = [backgroundColor CGColor];
}

@end