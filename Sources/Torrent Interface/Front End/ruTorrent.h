//
//  ruTorrent.h
//  Bar Magnet
//
//  Created by Charlotte Tortorella on 14/05/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#import "TorrentClient.h"

@interface ruTorrent : TorrentClient <NSXMLParserDelegate> {
  NSUInteger externalIterator;
  NSUInteger internalIterator;
  NSMutableArray *jobsDataArray;
}
@end
