//
//  TorrentDelegate.h
//  Bar Magnet
//
//  Created by Charlotte Tortorella on 8/04/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//
#import "TorrentClient.h"

@interface TorrentDelegate : NSObject

+ (TorrentDelegate *)sharedInstance;
- (TorrentClient *)currentlySelectedClient;
- (void)handleMagnet:(NSString *)magnetLink;
- (BOOL)handleTorrentFile:(NSURL *)url viewController:(UIViewController *)vc;

@property(nonatomic, strong) TorrentClient *currentlySelectedClient;
@property(nonatomic, strong) NSArray *torrentClasses;
@property(nonatomic, strong) NSDictionary *torrentDelegates;

@end
