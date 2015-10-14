//
//  XirvikSeedbox.m
//  BarMagnet
//
//  Created by Charlotte Tortorella on 26/09/2015.
//  Copyright © 2015 Carlo Tortorella. All rights reserved.
//

#import "NSData+BEncode.h"
#import "XirvikSeedbox.h"

@implementation XirvikSeedbox

+ (NSString *)name
{
	return @"Xirvik Seedbox";
}

+ (NSString *)defaultPort
{
	return @"443";
}

+ (BOOL)supportsRelativePath
{
	return NO;
}

+ (NSString *)relativePath
{
	return @"/rtorrent";
}

- (NSURLRequest *)virtualHandleMagnetLink:(NSString *)magnetLink
{
	NSURL * url = [[NSURL URLWithString:self.getAppendedURL] URLByAppendingPathComponent:@"php/addtorrent.php"];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
	[request setHTTPMethod:@"POST"];
	NSString * body = [NSString stringWithFormat:@"url=%@", [[magnetLink stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] encodeAmpersands]];
	[request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
	NSLog(@"%@", body);
	return request;
}

- (NSURLRequest *)virtualHandleTorrentFile:(NSData *)fileData withURL:(NSURL *)fileURL
{
	return [self virtualHandleMagnetLink:fileData.magnetLink];
}

- (NSString *)getUserFriendlyAppendedURL
{
	return [self.getBaseURL stringByAppendingString:[self.class relativePath]];
}

@end
