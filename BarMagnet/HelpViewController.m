//
//  HelpViewController.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 17/07/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "HelpViewController.h"

@implementation HelpViewController

- (IBAction)doneButton:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)emailDeveloper:(id)sender
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[[NSBundle mainBundle] infoDictionary][@"Email Address"]]];
}

@end