//
//  ruTorrent.h
//  Bar Magnet
//
//  Created by Carlo Tortorella on 14/05/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "TorrentClient.h"

@interface ruTorrent : TorrentClient <NSXMLParserDelegate>
{
	NSUInteger externalIterator;
	NSUInteger internalIterator;
	NSMutableArray * jobsDataArray;
}
@end
