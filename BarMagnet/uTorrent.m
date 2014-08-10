//
//  NSObject+PreferencesInterface.m
//  Magnet Fondler
//
//  Created by Carlo Tortorella on 11/03/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "uTorrent.h"
#import "FileHandler.h"
#import "NSData+BEncode.h"

@interface uTorrent () <NSXMLParserDelegate>
@property (nonatomic, strong) NSString * token;
@end

@implementation uTorrent

+ (NSString *)name
{
	return @"µTorrent";
}

+ (NSNumber *)completeNumber
{
    return @1000;
}

- (BOOL)isValidJobsData:(NSData *)data
{
	id JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
	return [JSON respondsToSelector:@selector(allKeys)] && [[JSON allKeys] containsObject:@"torrents"];
}

- (NSString *)statusFromBitField:(NSInteger)bitField
{
	if (bitField & (1 << 4))
	{
		return @"Error";
	}
	if (bitField & (1 << 7))
	{
		if (!(bitField & 1 << 0))
		{
			if (bitField & (1 << 6))
			{
				return @"Queued";
			}
			return @"Paused";
		}
		else if (bitField & (1 << 5))
		{
			return @"Paused";
		}
		else if (bitField & (1 << 8))
		{
			return @"Seeding";
		}
		else if (bitField & 1 << 0)
		{
			return @"Downloading";
		}
		else if (bitField & 1 << 1)
		{
			return @"Checking";
		}
	}
	return @"Unknown State";
}

- (NSMutableURLRequest *)tokenRequest
{
	return [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[[self getAppendedURL] stringByAppendingString:@"token.html"]]];
}

- (NSMutableURLRequest *)HTTPRequestWithMethod:(NSString *)method andHashes:(NSArray *)hashes
{
	storedURLString = [NSString stringWithFormat:@"%@?token=%%@&action=%@&hash=%@", [self getAppendedURL], method, [hashes componentsJoinedByString:@"&hash="]];
	storedRequest = [NSMutableURLRequest new];
	return [self tokenRequest];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	self.token = string;
}

- (NSMutableURLRequest *)checkTorrentJobs
{
	NSData * data = [NSURLConnection sendSynchronousRequest:[self tokenRequest] returningResponse:nil error:nil];
	NSXMLParser * parser = [NSXMLParser.alloc initWithData:data];
	parser.delegate = self;
	[parser parse];
	return [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?token=%@&list=1", self.getAppendedURL, self.token]]];
}

- (id)getTorrentJobs
{
	id JSON = [NSJSONSerialization JSONObjectWithData:self.jobsData options:0 error:nil];

	if ([JSON respondsToSelector:@selector(allKeys)])
	{
		if ([[NSSet setWithArray:[JSON allKeys]] containsObject:@"torrents"])
		{
			return JSON[@"torrents"];
		}
	}
	return nil;
}

- (NSDictionary *)virtualHandleTorrentJobs
{
	NSMutableDictionary * tempJobs = [NSMutableDictionary new];
	for (NSArray * array in [self getTorrentJobs])
	{
		NSInteger number = [array[4] isEqual:self.class.completeNumber] ? [array[1] intValue] | (1 << 8) : [array[1] intValue];
		NSString * status = [self statusFromBitField:number];

		if (array.count > 19)
		{

			[self insertTorrentJobsDictWithArray:@[array[0], array[2], array[4], status, [array[9] transferRateString], [array[8] transferRateString], [array[10] ETAString], [array[5] sizeString], [array[6] sizeString], array[3], array[12], array[14], array[9], array[8], @([array[7] integerValue] / 1000.), array[23], array[24]] intoDict:tempJobs];
		}
		else
		{

			[self insertTorrentJobsDictWithArray:@[array[0], array[2], array[4], status, [array[9] transferRateString], [array[8] transferRateString], [array[10] ETAString], [array[5] sizeString], [array[6] sizeString], array[3], array[12], array[14], array[9], array[8], @([array[7] integerValue] / 1000.)] intoDict:tempJobs];
		}
	}
	return tempJobs;
}

- (NSString *)getUserFriendlyAppendString
{
	return [self getURLAppendString];
}

- (NSString *)getURLAppendString
{
	return [[[FileHandler.sharedInstance webDataValueForKey:@"relative_path" andDict:nil] orSome:@"gui"] stringWithPrecedingAndSucceedingSlashes];
}

- (BOOL)receivedSuccessConditional:(NSData *)response
{
    return ![[[NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingAllowFragments error:nil] allKeys] containsObject:@"error"];
}

- (NSURLRequest *)virtualHandleMagnetLink:(NSString *)magnetLink
{
	//Submit the URL with authentication token to the server
	storedURLString = [NSString stringWithFormat:@"%@?token=%%@&action=add-url&s=%@", [self getAppendedURL], [[magnetLink encodeAmpersands] stringByReplacingOccurrencesOfString:@"%" withString:@"%%"]];
	storedRequest = [NSMutableURLRequest new];
	return [self tokenRequest];
}

- (NSURLRequest *)virtualHandleTorrentFile:(NSData *)fileData withURL:(NSURL *)fileURL
{
	NSLog(@"%@", fileData.magnetLink);
	return [self virtualHandleMagnetLink:fileData.magnetLink];

	NSMutableURLRequest * request = [NSMutableURLRequest new];
	NSString * boundary = [NSString stringWithFormat:@"AJAX-----------------------%f", [[NSDate new] timeIntervalSince1970]];
	NSMutableData * body = [NSMutableData new];
	
	[request setHTTPMethod:@"POST"];
	[request addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
	
	[body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"torrent_file\"; filename=\"%@\"\r\n", fileURL.absoluteString] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", @"application/x-bittorrent"] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:fileData];
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[request setHTTPBody:body];

	storedURLString = [NSString stringWithFormat:@"%@?token=%%@&action=add-file", self.getAppendedURL];
	storedRequest = request;

	return [self tokenRequest];
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
	return [self HTTPRequestWithMethod:removeData ? @"removedata" : @"remove" andHashes:@[hash]];
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
	if ([[response toUTF8String] rangeOfString:@"invalid request"].location != NSNotFound)
	{
		return @"Invalid request";
	}
	
	NSDictionary * JSONDict = [NSJSONSerialization JSONObjectWithData:response options:0 error:nil];

	if ([JSONDict respondsToSelector:@selector(objectForKey:)])
	{
		if ([JSONDict.allKeys containsObject:@"error"])
		{
			return JSONDict[@"error"];
		}
	}
	
	return [[response toUTF8String] sentenceParsedString];
}

+ (NSString *)defaultPort
{
	return @"8080";
}

+ (BOOL)supportsRelativePath
{
	return YES;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if ([[responseData toUTF8String] rangeOfString:@"<div id='token' style='display:none;'>"].location != NSNotFound && storedRequest)
	{
		[storedRequest setURL:[NSURL URLWithString:[NSString stringWithFormat:storedURLString, [[responseData toUTF8String] getStringBetween:@"<div id='token' style='display:none;'>" andString:@"</div>"]]]];
		responseData = [NSMutableData new];
		theConnection = [NSURLConnection connectionWithRequest:storedRequest delegate:self];
		storedRequest = nil;
	}
	else
	{
		[super connectionDidFinishLoading:connection];
	}
}

- (BOOL)supportsAddedDate
{
	return YES;
}

- (BOOL)supportsCompletedDate
{
	return YES;
}

@end
