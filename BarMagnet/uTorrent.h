//
//  NSObject+PreferencesInterface.h
//  Magnet Fondler
//
//  Created by Carlo Tortorella on 11/03/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#pragma once
#import "TorrentClient.h"

@interface uTorrent : TorrentClient
{
	NSString * storedURLString;
	NSString * magnetString;
	NSMutableURLRequest * storedRequest;
}

@end