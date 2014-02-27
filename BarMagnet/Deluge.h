//
//  Deluge.h
//  Bar Magnet
//
//  Created by Carlo Tortorella on 30/05/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "TorrentClient.h"

@interface Deluge : TorrentClient
{
    NSNumber * randomID;
    NSString * errorString;
}
@end
