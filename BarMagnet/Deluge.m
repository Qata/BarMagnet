//
//  Deluge.m
//  Bar Magnet
//
//  Created by Charlotte Tortorella on 30/05/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#import "Deluge.h"
#import "FileHandler.h"

#import "NSData+Base64.h"


@implementation Deluge

+ (NSString *)name
{
	return @"Deluge";
}

+ (NSNumber *)completeNumber
{
    return @100;
}

- (BOOL)isValidJobsData:(NSData *)data
{
	id JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
	if ([JSON respondsToSelector:@selector(objectForKey:)])
	{
		if ([[JSON allKeys] containsObject:@"result"])
		{
			return YES;
		}
	}
	return NO;
}

- (NSMutableURLRequest *)checkTorrentJobs
{
    NSMutableURLRequest * request = [self universalPOSTSetting];
	NSDictionary * JSONObject = @{@"id":@([randomID intValue] + 3), @"method":@"core.get_torrents_status", @"params":@[@{}, @[@"hash", @"name", @"progress", @"state", @"download_payload_rate", @"upload_payload_rate", @"eta", @"total_done", @"total_uploaded", @"total_size", @"num_peers", @"num_seeds", @"ratio"]]};
	[request setHTTPBody:[NSJSONSerialization dataWithJSONObject:JSONObject options:0 error:nil]];
    
	return request;
}

- (id)getTorrentJobs
{
	id JSON = [NSJSONSerialization JSONObjectWithData:self.jobsData options:0 error:nil];
	if ([JSON respondsToSelector:@selector(objectForKey:)])
	{
		if ([[NSSet setWithArray:[JSON allKeys]] containsObject:@"result"])
		{
			return JSON[@"result"];
		}
	}
	return NO;
}

- (NSDictionary *)virtualHandleTorrentJobs
{
    NSMutableDictionary * tempJobs = [NSMutableDictionary new];
	NSDictionary * torrentJobs = [self getTorrentJobs];

	if ([torrentJobs respondsToSelector:@selector(countByEnumeratingWithState:objects:count:)])
	{
		for (NSString * dictKey in torrentJobs)
		{
			if ([torrentJobs[dictKey] respondsToSelector:@selector(objectForKey:)])
			{
				NSDictionary * torrentDict = torrentJobs[dictKey];
				[self insertTorrentJobsDictWithArray:@[torrentDict[@"hash"], torrentDict[@"name"], torrentDict[@"progress"], torrentDict[@"state"], [torrentDict[@"download_payload_rate"] transferRateString], [torrentDict[@"upload_payload_rate"] transferRateString], [torrentDict[@"eta"] ETAString], [torrentDict[@"total_done"] sizeString], [torrentDict[@"total_uploaded"] sizeString], torrentDict[@"total_size"], torrentDict[@"num_peers"], torrentDict[@"num_seeds"], torrentDict[@"download_payload_rate"], torrentDict[@"upload_payload_rate"], @([torrentDict[@"total_done"] doubleValue] ? [torrentDict[@"total_uploaded"] doubleValue] / [torrentDict[@"total_done"] doubleValue] : 0)] intoDict:tempJobs];
			}
		}
	}
	return tempJobs;
}

- (NSString *)getUserFriendlyAppendString
{
	return [[[FileHandler.sharedInstance webDataValueForKey:@"relative_path" andDict:nil] orSome:@""] stringWithPrecedingSlash];
}

- (NSString *)getURLAppendString
{
	return [[NSURL URLWithString:[[[FileHandler.sharedInstance webDataValueForKey:@"relative_path" andDict:nil] orSome:@""] stringWithPrecedingSlash]] URLByAppendingPathComponent:@"json"].absoluteString;
}

- (BOOL)receivedSuccessConditional:(NSData *)response
{
    if ([response length])
    {
        NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:response options:0 error:nil];
        if ([responseDictionary respondsToSelector:@selector(objectForKey:)])
        {
            id resultObject = responseDictionary[@"result"];
            id errorObject = responseDictionary[@"error"];
            
            if (resultObject == nil)
            {
                if ([errorString length])
                {
                    return NO;
                }
                else
                {
                    errorString = @"Duplicate torrent";
                    return NO;
                }
            }
            else
            {
                if ([errorObject isKindOfClass:NSString.class] || [errorObject isKindOfClass:NSMutableString.class])
                {
                    errorString = errorObject;
                    return NO;
                }
                else if ([errorObject respondsToSelector:@selector(stringValue)])
                {
                    errorString = [errorObject stringValue];
                }
                else if ([errorObject respondsToSelector:@selector(localizedDescription)])
                {
                    errorString = [errorObject localizedDescription];
                }
            }
        }
    }
    else
    {
        return NO;
    }
    
	return YES;
}

- (NSString *)parseTorrentFailure:(NSData *)response
{
    NSString * retVal = errorString;
    errorString = nil;
    return [retVal length] ? retVal : @"An unknown error occurred";
}

- (NSMutableURLRequest *)universalPOSTSetting
{
    NSMutableURLRequest * retVal;
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.getAppendedURLWithoutAuth]];
    randomID = @(arc4random());
	[request setHTTPMethod:@"POST"];

    retVal = [request copy];

	NSError * error = nil;
    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:@{@"id":randomID, @"method":@"auth.login", @"params":@[[[self getWebDataForKey:@"password"] orSome:@""]]} options:0 error:nil]];
	if (error)
	{
		errorString = error.localizedDescription;
	}
    
    NSData * returnedData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    NSDictionary * dict = [returnedData length] ? [NSJSONSerialization JSONObjectWithData:returnedData options:0 error:nil] : nil;
    if ([dict respondsToSelector:@selector(objectForKey:)])
    {
        if ([dict[@"result"] isEqual:@NO])
        {
            errorString = @"Incorrect password";
        }
    }
	return retVal;
}

- (NSURLRequest *)virtualHandleMagnetLink:(NSString *)magnetLink
{
	NSMutableURLRequest * request = [self universalPOSTSetting];
	NSDictionary * options = @{};
	NSString * path = @"";
	if ([path = [[FileHandler.sharedInstance webDataValueForKey:@"directory" andDict:nil] orSome:@""] length])
	{
		options = @{@"download_location":path};
	}

	[request setHTTPBody:[NSJSONSerialization dataWithJSONObject:@{@"id":@([randomID intValue] + 1), @"method":@"core.add_torrent_magnet", @"params":@[magnetLink, options]} options:0 error:nil]];
	return request;
}

- (NSURLRequest *)virtualHandleTorrentFile:(NSData *)fileData withURL:(NSURL *)fileURL
{
	NSDictionary * options = @{};
	NSString * path = @"";
	if ([path = [[FileHandler.sharedInstance webDataValueForKey:@"directory" andDict:nil] orSome:@""] length])
	{
		options = @{@"download_location":path};
	}
	NSMutableURLRequest * request = [self universalPOSTSetting];
	[request setHTTPBody:[NSJSONSerialization dataWithJSONObject:@{@"id":@([randomID intValue] + 1), @"method":@"core.add_torrent_file", @"params":@[[fileURL absoluteString], [fileData base64EncodedString], options]} options:0 error:nil]];
	return request;
}

- (NSURLRequest *)virtualPauseTorrent:(NSString *)hash
{
	hash = hash.lowercaseString;
	NSMutableURLRequest * request = [self universalPOSTSetting];
	[request setHTTPBody:[NSJSONSerialization dataWithJSONObject:@{@"id":@([randomID intValue] + 1), @"method":@"core.pause_torrent", @"params":@[@[hash]]} options:0 error:nil]];
	return request;
}

- (NSURLRequest *)virtualResumeTorrent:(NSString *)hash
{
	hash = hash.lowercaseString;
	NSMutableURLRequest * request = [self universalPOSTSetting];
	[request setHTTPBody:[NSJSONSerialization dataWithJSONObject:@{@"id":@([randomID intValue] + 1), @"method":@"core.resume_torrent", @"params":@[@[hash]]} options:0 error:nil]];
	return request;
}

- (NSURLRequest *)virtualRemoveTorrent:(NSString *)hash removeData:(BOOL)removeData
{
	hash = hash.lowercaseString;
	NSMutableURLRequest * request = [self universalPOSTSetting];
	[request setHTTPBody:[NSJSONSerialization dataWithJSONObject:@{@"id":@([randomID intValue] + 1), @"method":@"core.remove_torrent", @"params":@[hash, @(removeData)]} options:0 error:nil]];
	return request;
}

- (NSURLRequest *)virtualPauseAllTorrents
{
	NSMutableURLRequest * request = [self universalPOSTSetting];
	[request setHTTPBody:[NSJSONSerialization dataWithJSONObject:@{@"id":@([randomID intValue] + 1), @"method":@"core.pause_all_torrents", @"params":@[]} options:0 error:nil]];
	return request;
}

- (NSURLRequest *)virtualResumeAllTorrents
{
	NSMutableURLRequest * request = [self universalPOSTSetting];
	[request setHTTPBody:[NSJSONSerialization dataWithJSONObject:@{@"id":@([randomID intValue] + 1), @"method":@"core.resume_all_torrents", @"params":@[]} options:0 error:nil]];
	return request;
}

+ (NSString *)defaultPort
{
	return @"8112";
}

+ (BOOL)supportsDirectoryChoice
{
	return YES;
}

+ (BOOL)supportsRelativePath
{
	return YES;
}

@end
