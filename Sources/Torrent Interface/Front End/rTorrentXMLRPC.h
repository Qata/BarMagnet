//
//  rTorrentXMLRPC.h
//  BarMagnet
//
//  Created by Charlotte Tortorella on 1/03/2014.
//  Copyright (c) 2014 Charlotte Tortorella. All rights reserved.
//

#import "TorrentClient.h"

@interface rTorrentXMLRPC : TorrentClient
- (NSMutableURLRequest *)RPCRequestWithMethodName:(NSString *)methodName view:(NSString *)view andParams:(NSArray *)params;
@end
