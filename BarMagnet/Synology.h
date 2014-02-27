//
//  Synology.h
//  Bar Magnet
//
//  Created by Carlo Tortorella on 19/07/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "TorrentClient.h"

@interface Synology : TorrentClient
{
	NSMutableURLRequest * storedRequest;
	NSDictionary * APIInfo;
	NSString * sid;
}

@end
