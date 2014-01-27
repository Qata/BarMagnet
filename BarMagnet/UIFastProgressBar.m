//
//  UIFastProgressBar.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 27/01/2014.
//  Copyright (c) 2014 Carlo Tortorella. All rights reserved.
//

#import "UIFastProgressBar.h"

@implementation UIFastProgressBar

- (void)awakeFromNib
{
	self.trackTintColor = [UIColor blueColor];
}

- (void)drawRect:(CGRect)rect
{
	[UIColor.lightGrayColor setFill];
	[[UIBezierPath bezierPathWithRect:self.frame] fill];
	CGRect progress = self.frame;
	progress.size.width *= self.progress;
	[self.trackTintColor setFill];
	[[UIBezierPath bezierPathWithRect:progress] fill];
}

@end
