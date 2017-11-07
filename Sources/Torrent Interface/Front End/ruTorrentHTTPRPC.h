//
//  ruTorrentHTTPRPC.h
//  BarMagnet
//
//  Created by Charlotte Tortorella on 3/07/2014.
//  Copyright (c) 2014 Charlotte Tortorella. All rights reserved.
//

#import "TorrentClient.h"

@interface ruTorrentHTTPRPC : TorrentClient
- (NSMutableURLRequest *)universalPOSTSetting;
- (NSMutableURLRequest *)RPCRequestWithMethodName:(NSString *)methodName;
@end
