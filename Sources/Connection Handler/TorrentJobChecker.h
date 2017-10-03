//
//  TorrentJobChecker.h
//  Bar Magnet
//
//  Created by Charlotte Tortorella on 7/05/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TorrentJobChecker : NSObject

+ (TorrentJobChecker *)sharedInstance;
- (void)jobCheckInvocation;
- (void)updateTorrentClientWithJobsData;
- (void)credentialsCheckInvocation;
- (void)connectionCheckInvocation;

@end
