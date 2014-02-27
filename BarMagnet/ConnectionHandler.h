//
//  ConnectionHandler.h
//  Bar Magnet
//
//  Created by Carlo Tortorella on 15/03/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ConnectionHandler : NSObject <NSURLConnectionDelegate>
{
	NSMutableData * responseData;
	NSURLConnection * theConnection;
	id theDelegate;
}

- (void)sendURLRequest:(NSURLRequest *)request delegate:(id)delegate;
+ (NSURLRequest *)createMultipartFormRequestWithHost:(NSURL *)host dispositionName:(NSString *)name fileURL:(NSURL *)fileURL andData:(NSData *)data;

@end
