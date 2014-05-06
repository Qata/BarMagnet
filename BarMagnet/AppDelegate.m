//
//  AppDelegate.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 4/06/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "AppDelegate.h"
#import "FileHandler.h"
#import "ConnectionHandler.h"
#import "TorrentDelegate.h"
#import "TorrentJobChecker.h"
#import "TSMessage.h"
#import <CoreMotion/CoreMotion.h>


@import AudioToolbox;

@interface AppDelegate ()
@property (nonatomic, strong) CMMotionManager * motionManager;
@end

@implementation AppDelegate

- (id)init
{
	if (self = [super init])
	{
		self.motionManager = [CMMotionManager new];
	}
	return self;
}
	
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#ifndef ANDROID
	[TestFlight takeOff:@"1d15ef35-8692-4cc4-9d94-96f36bb449b6"];
#endif

	if ([UIApplication.sharedApplication respondsToSelector:@selector(setMinimumBackgroundFetchInterval:)])
	{
		[UIApplication.sharedApplication setMinimumBackgroundFetchInterval:60];
	}

	if (![FileHandler.sharedInstance settingsValueForKey:@"sort_by"])
	{
		[FileHandler.sharedInstance setSettingsValue:@"Incomplete" forKey:@"sort_by"];
	}
	if (![FileHandler.sharedInstance settingsValueForKey:@"cell"])
	{
		[FileHandler.sharedInstance setSettingsValue:@"Pretty" forKey:@"cell"];
	}

	if (![NSUserDefaults.standardUserDefaults objectForKey:@"clients"])
	{
		if ([[[FileHandler.sharedInstance oldWebDataValueForKey:@"url"] orSome:@""] length])
		{
			NSString * url = [[FileHandler.sharedInstance oldWebDataValueForKey:@"url"] orSome:@""];
			NSString * username = [[FileHandler.sharedInstance oldWebDataValueForKey:@"username"] orSome:@""];
			NSString * password = [[FileHandler.sharedInstance oldWebDataValueForKey:@"password"] orSome:@""];
			NSString * port = [[FileHandler.sharedInstance oldWebDataValueForKey:@"port"] orSome:@""];
			NSNumber * useSSL = [[FileHandler.sharedInstance oldWebDataValueForKey:@"use_ssl"] orSome:@""];
			NSString * directory = [[FileHandler.sharedInstance oldWebDataValueForKey:@"directory"] orSome:@""];
			NSString * label = [[FileHandler.sharedInstance oldWebDataValueForKey:@"label"] orSome:@""];
			NSString * relative_path = [[FileHandler.sharedInstance oldWebDataValueForKey:@"relative_path"] orSome:@""];
			if ([url length])
			{
				[FileHandler.sharedInstance setSettingsValue:@"Default" forKey:@"server_name"];
				[NSUserDefaults.standardUserDefaults setObject:@[@{@"name":@"Default", @"url":url, @"type":[FileHandler.sharedInstance settingsValueForKey:@"server_type"], @"username":username, @"password":password, @"port":port, @"use_ssl":useSSL, @"directory":directory, @"label":label, @"relative_path":relative_path}] forKey:@"clients"];
			}
		}
	}
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(updateConnectionStatus)]];
	[invocation setTarget:self];
	[invocation setSelector:@selector(updateConnectionStatus)];
	[[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:[[FileHandler.sharedInstance settingsValueForKey:@"refresh_connection_seconds"] doubleValue] invocation:invocation repeats:YES] forMode:NSRunLoopCommonModes];

	invocation = [NSInvocation invocationWithMethodSignature:[[TorrentJobChecker sharedInstance] methodSignatureForSelector:@selector(updateTorrentClientWithJobsData)]];
	[invocation setTarget:[TorrentJobChecker sharedInstance]];
	[invocation setSelector:@selector(updateTorrentClientWithJobsData)];

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:[[FileHandler.sharedInstance settingsValueForKey:@"refresh_connection_seconds"] doubleValue] invocation:invocation repeats:YES] forMode:NSRunLoopCommonModes];
	});

    return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{

}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 6 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		completionHandler(UIBackgroundFetchResultNewData);
	});
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    [[TorrentDelegate sharedInstance] handleMagnet:url.absoluteString];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	[TorrentDelegate.sharedInstance.currentlySelectedClient becameIdle];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [FileHandler.sharedInstance saveAllPlists];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	[UIApplication.sharedApplication cancelAllLocalNotifications];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	[TorrentDelegate.sharedInstance.currentlySelectedClient becameActive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	[TorrentDelegate.sharedInstance.currentlySelectedClient willExit];
}

- (void)updateConnectionStatus
{
	[[TorrentJobChecker sharedInstance] performSelectorInBackground:@selector(connectionCheckInvocation) withObject:nil];
	[[TorrentJobChecker sharedInstance] performSelectorInBackground:@selector(jobCheckInvocation) withObject:nil];
}



@end
