//
//  TorrentDelegate.m
//  Bar Magnet
//
//  Created by Carlo Tortorella on 8/04/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "TorrentDelegate.h"
#import "FileHandler.h"
#import "uTorrent.h"
#import "Transmission.h"
#import "VuzeRemoteUI.h"
#import "ruTorrent.h"
#import "Deluge.h"
#import "qBittorrent.h"
#import "Synology.h"

@interface TorrentDelegate ()

@end

@implementation TorrentDelegate

static TorrentDelegate * sharedInstance;

+ (void)initialize
{
	static BOOL initialized = NO;
	if(!initialized)
	{
		initialized = YES;
		sharedInstance = [TorrentDelegate new];
	}
}

+ (TorrentDelegate *)sharedInstance
{
	return sharedInstance;
}

- (id)init
{
	if (self = [super init])
	{
		self.torrentClasses = @[uTorrent.class, Transmission.class, VuzeRemoteUI.class, ruTorrent.class, Deluge.class, qBittorrent.class, Synology.class];
		NSMutableDictionary * dict = NSMutableDictionary.new;
		for (Class class in self.torrentClasses)
		{
			[dict setObject:class forKey:[class name]];
		}
		self.torrentDelegates = dict;
		[self changeClient];
	}
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(changeClient) name:@"ChangedClient" object:nil];
	return self;
}

- (void)dealloc
{
	[NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)changeClient
{
	[self.currentlySelectedClient becameIdle];
	NSString * serverName = [FileHandler.sharedInstance settingsValueForKey:@"server_name"];
	for (NSDictionary * dict in [NSUserDefaults.standardUserDefaults objectForKey:@"clients"])
	{
		if ([dict[@"name"] isEqualToString:serverName])
		{
			for (NSString * name in self.torrentDelegates)
			{
				if ([name isEqualToString:dict[@"type"]])
				{
					self.currentlySelectedClient = [self.torrentDelegates[name] new];
					break;
				}
			}
		}
	}
	[self.currentlySelectedClient becameActive];
}

- (void)handleMagnet:(NSString *)magnetLink
{
	[self.currentlySelectedClient handleMagnetLink:magnetLink];
}

- (BOOL)handleTorrentFile:(NSString *)fileName
{
	BOOL retVal = NO;

	if ([fileName length] && [fileName rangeOfString:@".torrent"].location != NSNotFound)
	{
		if ([[fileName substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"http"])
		{
			[self.currentlySelectedClient handleTorrentURL:[NSURL URLWithString:[fileName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
		}
		else
		{
			[self.currentlySelectedClient handleTorrentFile:fileName];
		}
		retVal = YES;
	}
	return retVal;
}

@end
