//
//  Transmission.h
//  Bar Magnet
//
//  Created by Carlo Tortorella on 16/03/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#pragma once
#import "TorrentClient.h"

@interface Transmission : TorrentClient
{
	NSMutableURLRequest * storedRequest;
}
@end
