//
//  ConnectionHandler.m
//  Bar Magnet
//
//  Created by Charlotte Tortorella on 15/03/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#import "ConnectionHandler.h"

@implementation ConnectionHandler

- (void)sendURLRequest:(NSURLRequest *)request delegate:(id)delegate
{
	responseData = [NSMutableData new];
	theConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	theDelegate = delegate;
}

+ (NSURLRequest *)createMultipartFormRequestWithHost:(NSURL *)host dispositionName:(NSString *)name fileURL:(NSURL *)fileURL andData:(NSData *)data
{
	//Submit the URL with authentication token to the server
	NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:host];
	NSString * boundary = [NSString stringWithFormat:@"AJAX-----------------------%f", [[[NSDate alloc] init] timeIntervalSince1970]];
	NSMutableData * body = [NSMutableData alloc];
	
	[request setHTTPMethod:@"POST"];
	[request addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
	
	[body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", name, fileURL.absoluteString] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", @"application/x-bittorrent"] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:data];
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[request setHTTPBody:body];
	
	return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[responseData appendData:data];
}

@end
