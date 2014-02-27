//
//  TorrentJobChecker.h
//  Bar Magnet
//
//  Created by Carlo Tortorella on 7/05/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TorrentJobChecker : NSObject

+ (TorrentJobChecker *)sharedInstance;
- (void)jobCheckInvocation;
- (void)updateTorrentClientWithJobsData;
- (void)credentialsCheckInvocation;

@end