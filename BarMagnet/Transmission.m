//
//  Transmission.m
//  Bar Magnet
//
//  Created by Carlo Tortorella on 16/03/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "Transmission.h"
#import "FileHandler.h"
#import "NSData+Base64.h"

@implementation Transmission

+ (NSString *)name
{
	return @"Transmission";
}

+ (NSNumber *)completeNumber
{
    return @1;
}

- (BOOL)isValidJobsData:(NSData *)data
{
	id JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

	if ([JSON respondsToSelector:@selector(objectForKey:)])
	{
		if ([JSON[@"arguments"] respondsToSelector:@selector(objectForKey:)])
		{
			if ([[JSON[@"arguments"] allKeys] containsObject:@"torrents"])
			{
				return YES;
			}
		}
	}
	return NO;
}

- (NSMutableURLRequest *)HTTPRequestWithMethod:(NSString *)method andHashes:(NSArray *)hashes
{
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.getAppendedURL]];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:[NSJSONSerialization dataWithJSONObject:@{@"method":method, @"arguments":@{@"ids":hashes}} options:0 error:nil]];
	storedRequest = request;

	return [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.getAppendedURL]];
}

- (NSMutableURLRequest *)checkTorrentJobs
{
	NSMutableURLRequest * aRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.getAppendedURL]];
	NSString * localToken = [[[NSURLConnection sendSynchronousRequest:aRequest returningResponse:nil error:nil] toUTF8String] getStringBetween:@"X-Transmission-Session-Id: " andString:@"</code>"];
	
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.getAppendedURL]];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request setValue:localToken forHTTPHeaderField:@"X-Transmission-Session-Id"];
	
	[request setHTTPBody:[NSJSONSerialization dataWithJSONObject:@{@"method":@"torrent-get", @"arguments":@{@"fields":@[@"hashString", @"name", @"percentDone", @"status", @"sizeWhenDone", @"downloadedEver", @"uploadedEver", @"peersGettingFromUs", @"peersSendingToUs", @"rateDownload", @"rateUpload", @"eta", @"uploadRatio", @"addedDate", @"doneDate"]}} options:0 error:nil]];
	
	return request;
}

- (NSDictionary *)getTorrentJobs
{
	id JSON = [NSJSONSerialization JSONObjectWithData:jobsData options:0 error:nil];

	if ([JSON respondsToSelector:@selector(objectForKey:)])
	{
		if ([JSON[@"arguments"] respondsToSelector:@selector(objectForKey:)])
		{
			if ([[JSON[@"arguments"] allKeys] containsObject:@"torrents"])
			{
				return JSON[@"arguments"][@"torrents"];
			}
		}
	}
	return nil;
}

- (NSDictionary *)virtualHandleTorrentJobs
{
	NSMutableDictionary * tempJobs = [NSMutableDictionary new];

	for (NSDictionary * dict in [self getTorrentJobs])
	{
		NSString * status = @"";

		switch ([dict[@"status"] intValue])
		{
			case 0:
				status = @"Paused";
				break;
			case 3:
				status = @"Download Queued";
				break;
			case 4:
				status = @"Downloading";
				break;
			case 6:
				status = @"Seeding";
				break;
		}

		NSString * ETA = [dict[@"eta"] intValue] != -2 ? [dict[@"eta"] ETAString] : @"∞";
		if (dict[@"hashString"])
		{
			[self insertTorrentJobsDictWithArray:@[dict[@"hashString"], dict[@"name"], dict[@"percentDone"], status, [dict[@"rateDownload"] transferRateString], [dict[@"rateUpload"] transferRateString], ETA, [dict[@"downloadedEver"] sizeString], [dict[@"uploadedEver"] sizeString], dict[@"sizeWhenDone"], dict[@"peersGettingFromUs"], dict[@"peersSendingToUs"], dict[@"rateDownload"], dict[@"rateUpload"], dict[@"uploadRatio"], dict[@"addedDate"], dict[@"doneDate"]] intoDict:tempJobs];
		}
	}
	
	return tempJobs;
}

- (NSString *)getUserFriendlyAppendString
{
	return @"/transmission/web/";
}

- (NSString *)getURLAppendString
{
	return @"/transmission/rpc/";
}

- (BOOL)receivedSuccessConditional:(NSData *)response
{
	return [[NSJSONSerialization JSONObjectWithData:response options:0 error:nil][@"result"] isEqual:@"success"];
}

- (NSURLRequest *)virtualHandleMagnetLink:(NSString *)magnetLink
{
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.getAppendedURL]];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

	NSMutableDictionary * arguments = [NSMutableDictionary dictionaryWithDictionary:@{@"filename":magnetLink}];
	NSString * directory = [[FileHandler.sharedInstance webDataValueForKey:@"directory" andDict:nil] orSome:@""];

	if (directory.length)
	{
		[arguments setObject:directory forKey:@"download-dir"];
	}

	[request setHTTPBody:[NSJSONSerialization dataWithJSONObject:@{@"method":@"torrent-add", @"arguments":arguments} options:0 error:nil]];
	storedRequest = request;

	return [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.getAppendedURL]];
}

- (NSURLRequest *)virtualHandleTorrentFile:(NSData *)fileData withURL:(NSURL *)fileURL
{
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.getAppendedURL]];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

	NSMutableDictionary * arguments = [NSMutableDictionary dictionaryWithDictionary:@{@"metainfo":[fileData base64EncodedString]}];
	NSString * directory = [[FileHandler.sharedInstance webDataValueForKey:@"directory" andDict:nil] orSome:@""];

	if (directory.length)
	{
		[arguments setObject:directory forKey:@"download-dir"];
	}

	[request setHTTPBody:[NSJSONSerialization dataWithJSONObject:@{@"method":@"torrent-add", @"arguments":arguments} options:0 error:nil]];
	storedRequest = request;

	return [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.getAppendedURL]];
}
- (NSURLRequest *)virtualPauseTorrent:(NSString *)hash
{
	return [self HTTPRequestWithMethod:@"torrent-stop" andHashes:@[hash]];
}

- (NSURLRequest *)virtualResumeTorrent:(NSString *)hash
{
	return [self HTTPRequestWithMethod:@"torrent-start" andHashes:@[hash]];
}

- (NSURLRequest *)virtualRemoveTorrent:(NSString *)hash removeData:(BOOL)removeData
{
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.getAppendedURL]];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:[NSJSONSerialization dataWithJSONObject:@{@"method":@"torrent-remove", @"arguments":@{@"ids":@[hash], @"delete-local-data":@(removeData)}} options:0 error:nil]];
	storedRequest = request;

	return [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.getAppendedURL]];
}

- (NSURLRequest *)virtualPauseAllTorrents
{
	return [self HTTPRequestWithMethod:@"torrent-stop" andHashes:self.getJobsDict.allKeys];
}

- (NSURLRequest *)virtualResumeAllTorrents
{
	return [self HTTPRequestWithMethod:@"torrent-start" andHashes:self.getJobsDict.allKeys];
}

- (NSString *)parseTorrentFailure:(NSData *)response
{
	NSError * error = nil;
	id JSON = [NSJSONSerialization JSONObjectWithData:response options:0 error:&error];
	if (error)
	{
		if ([response.toUTF8String rangeOfString:@"<h1>401: Unauthorized</h1>"].location != NSNotFound)
		{
			return @"Incorrect or missing user credentials.";
		}
	}

	return [JSON respondsToSelector:@selector(objectForKey:)] ? [JSON objectForKey:@"result"] : nil;
}

+ (NSString *)defaultPort
{
	return @"9091";
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if ([[responseData toUTF8String] rangeOfString:@"X-Transmission-Session-Id"].location != NSNotFound && storedRequest)
	{
		[storedRequest setValue:[responseData.toUTF8String getStringBetween:@"X-Transmission-Session-Id: " andString:@"</code>"] forHTTPHeaderField:@"X-Transmission-Session-Id"];
		responseData = NSMutableData.new;
		theConnection = [NSURLConnection connectionWithRequest:storedRequest delegate:self];
		storedRequest = nil;
	}
	else
	{
		[super connectionDidFinishLoading:connection];
	}
}

+ (BOOL)supportsDirectoryChoice
{
	return YES;
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