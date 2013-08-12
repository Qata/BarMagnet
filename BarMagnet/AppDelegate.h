//
//  AppDelegate.h
//  BarMagnet
//
//  Created by Carlo Tortorella on 4/06/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PingHandler;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
	PingHandler * pingHandler;
}

@property (strong, nonatomic) UIWindow *window;

@end
