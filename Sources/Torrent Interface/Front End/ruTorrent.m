//
//  ruTorrent.m
//  Bar Magnet
//
//  Created by Charlotte Tortorella on 14/05/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#import "ruTorrent.h"
#import "NSData+BEncode.h"
#import "FileHandler.h"

enum
{
	PAUSING = 0,
	STARTED = 1,
	PAUSED = 1 << 1,
	CHECKING = 1 << 2,
	HASHING = 1 << 3,
	ERROR = 1 << 4
};

@implementation ruTorrent

+ (NSString *)name
{
	return @"ruTorrent";
}

+ (NSNumber *)completeNumber
{
    return @1;
}

- (NSMutableURLRequest *)HTTPRequestWithMethod:(NSString *)method andHashes:(NSArray *)hashes
{
	return [NSMutableURLRequest requestWithURL:[[NSURL URLWithString:self.getAppendedURL] URLByAppendingPathComponent:[NSString stringWithFormat:@"php/rpc.php?action=%@&hashes=%@", method, [hashes componentsJoinedByString:@","]]]];
}

- (NSMutableURLRequest *)checkTorrentJobs
{
	return [NSMutableURLRequest requestWithURL:[[NSURL URLWithString:self.getAppendedURL] URLByAppendingPathComponent:[NSString stringWithFormat:@"php/rpc.php?action=list&args=%@", [@[@"get_hash", @"get_state", @"get_name", @"get_down_rate", @"get_up_rate", @"get_bytes_done", @"get_up_total", @"get_size_bytes", @"get_peers_accounted", @"get_peers_complete", @"is_open", @"get_creation_date"] componentsJoinedByString:@","]]]];
}

- (id)getTorrentJobs
{
	return [[NSJSONSerialization JSONObjectWithData:self.jobsData options:0 error:nil] objectForKey:@"torrents"];
}

- (NSDictionary *)virtualHandleTorrentJobs
{
	NSMutableDictionary * tempJobs = [NSMutableDictionary new];
	for (NSDictionary * dict in [self getTorrentJobs])
	{
		NSNumber * percentDone = @0;
		if ([dict[@"get_bytes_done"] doubleValue] && [dict[@"get_size_bytes"] doubleValue])
		{
			percentDone = @([dict[@"get_bytes_done"] doubleValue] / [dict[@"get_size_bytes"] doubleValue]);
		}
		NSString * status = @"";
		switch ([dict[@"get_state"] intValue])
		{
			case STARTED:
				status = [percentDone intValue] != 1 ? @"Downloading" : @"Seeding";
				break;
			case PAUSED:
			case PAUSING:
				status = @"Paused";
				break;
			case CHECKING:
				status = @"Checking";
				break;
			case HASHING:
				status = @"Hashing";
				break;
			case ERROR:
				status = @"Error";
				break;
		}
		NSString * ETA = @"";
		if ([dict[@"get_down_rate"] integerValue] && ![percentDone isEqual:[[self class] completeNumber]])
		{
			ETA = [@(([dict[@"get_size_bytes"] integerValue] - [dict[@"get_bytes_done"] integerValue]) / [dict[@"get_down_rate"] integerValue]) ETAString];
		}
		[self insertTorrentJobsDictWithArray:@[dict[@"get_hash"], dict[@"get_name"], percentDone, status, [dict[@"get_down_rate"] transferRateString], [dict[@"get_up_rate"] transferRateString], ETA, [dict[@"get_bytes_done"] sizeString], [dict[@"get_up_total"] sizeString], [dict[@"get_size_bytes"] toNumber], dict[@"get_peers_accounted"], dict[@"get_peers_complete"], dict[@"get_down_rate"], dict[@"get_up_rate"], @([dict[@"get_bytes_done"] doubleValue] ? [dict[@"get_up_total"] doubleValue] / [dict[@"get_bytes_done"] doubleValue] : 0), dict[@"get_creation_date"]] intoDict:tempJobs];
	}
	return tempJobs;
}

- (BOOL)isValidJobsData:(NSData *)data
{
	NSError * error = nil;
	id JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
	return error ? NO : [[JSON objectForKey:@"success"] boolValue];
}

- (NSString *)getUserFriendlyAppendString
{
	return self.getURLAppendString;
}

- (NSString *)getURLAppendString
{
	return [[FileHandler.sharedInstance webDataValueForKey:@"relative_path"] orSome:@""];
}

- (BOOL)receivedSuccessConditional:(NSData *)response
{
	NSError * error = nil;
	id JSON = [NSJSONSerialization JSONObjectWithData:response options:0 error:&error];
	if (!error)
	{
		return YES;
	}
	return [[response toUTF8String] rangeOfString:@"addTorrentSuccess"].location != NSNotFound || [[JSON objectForKey:@"success"] boolValue];
}

- (NSURLRequest *)virtualPauseTorrent:(NSString *)hash
{
	return [self HTTPRequestWithMethod:@"stop" andHashes:@[hash]];
}

- (NSURLRequest *)virtualResumeTorrent:(NSString *)hash
{
	return [self HTTPRequestWithMethod:@"start" andHashes:@[hash]];
}

- (NSURLRequest *)virtualRemoveTorrent:(NSString *)hash removeData:(BOOL)removeData
{
	return [self HTTPRequestWithMethod:@"erase" andHashes:@[hash]];
}

- (NSURLRequest *)virtualPauseAllTorrents
{
	return [self HTTPRequestWithMethod:@"stop" andHashes:self.getJobsDict.allKeys];
}

- (NSURLRequest *)virtualResumeAllTorrents
{
	return [self HTTPRequestWithMethod:@"start" andHashes:self.getJobsDict.allKeys];
}

- (NSString *)parseTorrentFailure:(NSData *)response
{
	NSError * error = nil;
	id JSON = [NSJSONSerialization JSONObjectWithData:response options:0 error:&error];

	if (error)
	{
		NSString * plainText = [NSString.alloc initWithData:response encoding:NSUTF8StringEncoding];

		if ([plainText rangeOfString:@"<h1>Not Found</h1>"].location != NSNotFound)
		{
			return @"Either you don't have rpc.php or you didn't set the relative path";
		}
		else
		{
			return @"An unexpected error occurred";
		}
	}

	return [JSON objectForKey:@"error"];
}

- (NSMutableURLRequest *)universalPOSTSetting
{
	NSString * dir = [[FileHandler.sharedInstance webDataValueForKey:@"directory"] orSome:@""];
	NSString * label = [[FileHandler.sharedInstance webDataValueForKey:@"label"] orSome:@""];

	NSMutableArray * requestAppend = [NSMutableArray new];

	[dir length] ? [requestAppend addObject:[NSString stringWithFormat:@"dir_edit=%@", [dir stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]] : nil;
	[label length] ? [requestAppend addObject:[NSString stringWithFormat:@"label=%@", [label stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]] : nil;

	NSURL * url = [[NSURL URLWithString:self.getAppendedURL] URLByAppendingPathComponent:[@"php/addtorrent.php?" stringByAppendingString:[requestAppend componentsJoinedByString:@"&"]]];

	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
	[request setHTTPMethod:@"POST"];

	return request;
}

- (NSURLRequest *)virtualHandleMagnetLink:(NSString *)magnetLink
{
	NSMutableURLRequest * request = [self universalPOSTSetting];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:[[@"url=" stringByAppendingString:[[magnetLink stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] encodeAmpersands]] dataUsingEncoding:NSUTF8StringEncoding]];

	return request;
}

- (NSURLRequest *)virtualHandleTorrentFile:(NSData *)fileData withURL:(NSURL *)fileURL
{
	NSMutableURLRequest * request = [self universalPOSTSetting];
	NSString * dir = [[FileHandler.sharedInstance webDataValueForKey:@"directory"] orSome:@""];
	NSString * label = [[FileHandler.sharedInstance webDataValueForKey:@"label"] orSome:@""];
	NSString * boundary = [NSString stringWithFormat:@"AJAX-----------------------%f", [[NSDate new] timeIntervalSince1970]];
	NSMutableData * body = [NSMutableData new];
	[request setHTTPMethod:@"POST"];
	[request addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
	
	if ([dir length])
	{
		[body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"dir_edit\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"%@\r\n", dir] dataUsingEncoding:NSUTF8StringEncoding]];
	}
	if ([label length])
	{
		[body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"tadd_label\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"%@\r\n", label] dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	[body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"torrent_file\"; filename=\"%@\"\r\n", fileURL.absoluteString] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", @"application/x-bittorrent"] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:fileData];
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[request setHTTPBody:body];
	
	return request;
}

+ (NSString *)defaultPort
{
	return @"80";
}

- (NSInteger)windowChangeHeightValue
{
	return WCS_ALL_FIELDS_HEIGHT;
}

+ (BOOL)supportsRelativePath
{
	return YES;
}

- (BOOL)supportsEraseChoice
{
	return NO;
}

+ (BOOL)supportsDirectoryChoice
{
	return YES;
}

- (BOOL)supportsAddedDate
{
	return YES;
}

@end
