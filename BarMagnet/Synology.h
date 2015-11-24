//
//  Synology.h
//  Bar Magnet
//
//  Created by Charlotte Tortorella on 19/07/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#import "TorrentClient.h"

@interface Synology : TorrentClient
{
	NSMutableURLRequest * storedRequest;
	NSDictionary * APIInfo;
	NSString * sid;
}

@end
