//
//  TorrentFileHandler.m
//  BarMagnet
//
//  Created by Charlotte Tortorella on 15/07/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#import "TorrentFileHandler.h"
#import "TorrentClient.h"
#import "TorrentDelegate.h"

@implementation TorrentFileHandler

- (void)downloadTorrentFile:(NSURL *)fileURL withDelegate:(id)delegate {
  responseData = [NSMutableData new];
  theDelegate = delegate;
  request = [NSMutableURLRequest requestWithURL:fileURL];
  theConnection = [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  [TorrentDelegate.sharedInstance.currentlySelectedClient handleTorrentData:responseData withURL:request.URL];
}

@end
