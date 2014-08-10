//
//  ruTorrentHTTPRPC.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 3/07/2014.
//  Copyright (c) 2014 Carlo Tortorella. All rights reserved.
//

#import "ruTorrentHTTPRPC.h"
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

@implementation ruTorrentHTTPRPC

- (NSMutableURLRequest *)RPCRequestWithMethodName:(NSString *)methodName
{
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[self.getAppendedURL stringByAppendingString:@"plugins/httprpc/action.php"]]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[[NSString stringWithFormat:@"mode=%@", methodName] dataUsingEncoding:NSUTF8StringEncoding]];
	return request;
}

+ (NSString *)name
{
	return @"ruTorrent HTTPRPC";
}

+ (NSNumber *)completeNumber
{
	return @1;
}

- (NSMutableURLRequest *)checkTorrentJobs
{
	return [self RPCRequestWithMethodName:@"list"];
}

- (id)getTorrentJobs
{
	return [NSJSONSerialization JSONObjectWithData:self.jobsData options:0 error:nil];
}

- (NSDictionary *)virtualHandleTorrentJobs
{
	NSMutableDictionary * tempJobs = [NSMutableDictionary new];
	NSDictionary * dict = [self getTorrentJobs][@"t"];
	for (NSString * key in dict)
	{
		NSArray * td = dict[key];
		if (td.count >= 34)
		{
			NSNumber * percentDone = @0;
			if ([td[8] doubleValue] && [td[5] doubleValue])
			{
				percentDone = @([td[8] doubleValue] / [td[5] doubleValue]);
			}

			NSString * ETA = @"";
			if ([td[12] integerValue] && ![percentDone isEqual:[[self class] completeNumber]])
			{
				ETA = [@(([td[5] integerValue] - [td[8] integerValue]) / [td[12] integerValue]) ETAString];
			}

			NSString * status = @"";
			switch ([td[3] intValue])
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

			[self insertTorrentJobsDictWithArray:@[key, td[4], percentDone, status, [td[12] transferRateString], [td[11] transferRateString], ETA, [td[8] sizeString], [td[9] sizeString], [td[5] toNumber], td[15], td[18], td[12], td[11], @([td[8] doubleValue] ? [td[9] doubleValue] / [td[8] doubleValue] : 0), td[21]] intoDict:tempJobs];
		}
	}
	return tempJobs;
}

- (BOOL)isValidJobsData:(NSData *)data
{
	NSError * error = nil;
	[NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
	return error ? NO : YES;
}

- (NSMutableURLRequest *)universalPOSTSetting
{
	NSString * url = [NSMutableString stringWithFormat:@"%@php/addtorrent.php?", self.getAppendedURL];

	NSString * dir = [[FileHandler.sharedInstance webDataValueForKey:@"directory" andDict:nil] orSome:@""];
	NSString * label = [[FileHandler.sharedInstance webDataValueForKey:@"label" andDict:nil] orSome:@""];

	NSMutableArray * requestAppend = [NSMutableArray new];

	[dir length] ? [requestAppend addObject:[NSString stringWithFormat:@"dir_edit=%@", [dir stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]] : nil;
	[label length] ? [requestAppend addObject:[NSString stringWithFormat:@"label=%@", [label stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]] : nil;

	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[url stringByAppendingString:[requestAppend componentsJoinedByString:@"&"]]]];
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
	NSString * dir = [[FileHandler.sharedInstance webDataValueForKey:@"directory" andDict:nil] orSome:@""];
	NSString * label = [[FileHandler.sharedInstance webDataValueForKey:@"label" andDict:nil] orSome:@""];
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

- (NSString *)getUserFriendlyAppendString
{
	return [[[FileHandler.sharedInstance webDataValueForKey:@"relative_path" andDict:nil] orSome:@""] stringWithPrecedingAndSucceedingSlashes];
}

- (NSString *)getURLAppendString
{
	return [[[FileHandler.sharedInstance webDataValueForKey:@"relative_path" andDict:nil] orSome:@""] stringWithPrecedingAndSucceedingSlashes];
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
	return [self RPCRequestWithMethodName:[NSString stringWithFormat:@"stop&hash=%@", hash]];
}

- (NSURLRequest *)virtualResumeTorrent:(NSString *)hash
{
	return [self RPCRequestWithMethodName:[NSString stringWithFormat:@"start&hash=%@", hash]];
}

- (NSURLRequest *)virtualRemoveTorrent:(NSString *)hash removeData:(BOOL)removeData
{
	return [self RPCRequestWithMethodName:[NSString stringWithFormat:@"remove&hash=%@", hash]];
}

- (NSURLRequest *)virtualPauseAllTorrents
{
	return [self RPCRequestWithMethodName:[NSString stringWithFormat:@"stop&hash=%@", [self.getJobsDict.allKeys componentsJoinedByString:@"&hash="]]];
}

- (NSURLRequest *)virtualResumeAllTorrents
{
	return [self RPCRequestWithMethodName:[NSString stringWithFormat:@"start&hash=%@", [self.getJobsDict.allKeys componentsJoinedByString:@"&hash="]]];
}

- (NSString *)parseTorrentFailure:(NSData *)response
{
	return @"An unexpected error occurred";
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

- (BOOL)supportsAddedDate
{
	return YES;
}

@end
