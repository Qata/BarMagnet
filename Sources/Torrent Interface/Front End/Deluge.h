//
//  Deluge.h
//  Bar Magnet
//
//  Created by Charlotte Tortorella on 30/05/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#import "TorrentClient.h"

@interface Deluge : TorrentClient {
    NSNumber *randomID;
    NSString *errorString;
}
@end
