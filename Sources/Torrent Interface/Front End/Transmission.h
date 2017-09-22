//
//  Transmission.h
//  Bar Magnet
//
//  Created by Charlotte Tortorella on 16/03/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#pragma once
#import "TorrentClient.h"

@interface Transmission : TorrentClient {
  NSMutableURLRequest *storedRequest;
}
@end
