//
//  TorrentJobChecker.m
//  Bar Magnet
//
//  Created by Carlo Tortorella on 7/05/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "TorrentJobChecker.h"
#import "TorrentDelegate.h"
#import "FileHandler.h"
#import "TorrentClient.h"
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import "TSMessage.h"
#endif

@implementation TorrentJobChecker

static TorrentJobChecker * sharedInstance;

+ (void)initialize
{
	static BOOL initialized = NO;
	if(!initialized)
	{
		initialized = YES;
		sharedInstance = [TorrentJobChecker new];
	}
}

+ (TorrentJobChecker *)sharedInstance
{
	return sharedInstance;
}

- (void)updateTorrentClientWithJobsData
{
	[TorrentDelegate.sharedInstance.currentlySelectedClient handleTorrentJobs];
	[NSNotificationCenter.defaultCenter postNotificationName:@"update_torrent_jobs_table" object:nil];
}

- (void)jobCheckInvocation
{
	@autoreleasepool
	{
		NSMutableURLRequest * request = [TorrentDelegate.sharedInstance.currentlySelectedClient checkTorrentJobs];
		[request setTimeoutInterval:8];
		if (request)
		{
			[NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:request.URL.host];
			NSData * receivedData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
			if ([receivedData length])
			{
				if ([TorrentDelegate.sharedInstance.currentlySelectedClient isValidJobsData:receivedData])
				{
					[TorrentDelegate.sharedInstance.currentlySelectedClient setJobsData:receivedData];
				}
				else
				{
					NSLog(@"Incorrect response to request for jobs data: %@", [receivedData toUTF8String]);
				}
			}
		}
	}
}

- (void)connectionCheckInvocation
{
	@autoreleasepool
	{
		NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[TorrentDelegate.sharedInstance.currentlySelectedClient getAppendedURL]]];
		[request setTimeoutInterval:8];
		if (request)
		{
			NSData * receivedData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
			if (![receivedData length])
			{
				[request setURL:[NSURL URLWithString:[TorrentDelegate.sharedInstance.currentlySelectedClient getUserFriendlyAppendedURL]]];
				receivedData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
			}
			[TorrentDelegate.sharedInstance.currentlySelectedClient setHostOnline:receivedData.length];
			[NSNotificationCenter.defaultCenter postNotificationName:@"update_torrent_jobs_header" object:nil];
		}
	}
}

- (void)credentialsCheckInvocation
{
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	@autoreleasepool
	{
		NSMutableURLRequest * request = [TorrentDelegate.sharedInstance.currentlySelectedClient checkTorrentJobs];
		[request setTimeoutInterval:8];
		if (request)
		{
			NSError * error = nil;
			NSData * receivedData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
			NSString * notification = nil;
			if (error)
			{
				if (error.code == -1012)
				{
					notification = @"Incorrect or missing user credentials.";
				}
				else
				{
					notification = [error localizedDescription];
				}
			}
			else if (![TorrentDelegate.sharedInstance.currentlySelectedClient isValidJobsData:receivedData])
			{
				if (receivedData.length > 1)
				{
					notification = [[TorrentDelegate.sharedInstance.currentlySelectedClient parseTorrentFailure:receivedData] sentenceParsedString];
				}
				else
				{
					notification = @"No error info provided, are you sure that's the right port?";
				}
			}

			if (notification)
			{
				[TSMessage showNotificationWithTitle:@"Unable to authenticate" subtitle:notification type:TSMessageNotificationTypeError];
			}
		}
	}
#endif
}

@end