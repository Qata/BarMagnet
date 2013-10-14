//
//  WebViewNavigationController.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 30/09/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "WebViewNavigationController.h"

@interface WebViewNavigationController ()

@end

@implementation WebViewNavigationController

- (BOOL)shouldAutorotate
{
    return [self.viewControllers.lastObject shouldAutorotate];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return [self.viewControllers.lastObject supportedInterfaceOrientations];
}

@end