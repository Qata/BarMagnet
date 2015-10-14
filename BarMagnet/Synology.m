//
//  Synology.m
//  Bar Magnet
//
//  Created by Carlo Tortorella on 19/07/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "Synology.h"
#import "ConnectionHandler.h"
#import "NSData+BEncode.h"

#if !TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
#import "NotificationHandler.h"
#endif

@implementation Synology

+ (NSString *)name
{
	return @"Synology";
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
		if ([JSON[@"data"] respondsToSelector:@selector(objectForKey:)])
		{
			if ([[JSON[@"data"] allKeys] containsObject:@"tasks"])
			{
				return YES;
			}
		}
	}
	return NO;
}

- (id)init
{
	if (self = [super init])
	{
		sid = nil;
		APIInfo = nil;
#if !TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(becameActive) name:NSWorkspaceDidWakeNotification object:nil];
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(becameIdle) name:NSWorkspaceWillSleepNotification object:nil];
#endif
	}
	return self;
}

- (void)dealloc
{
	[NSNotificationCenter.defaultCenter removeObserver:self];
}

- (NSURLRequest *)APIRequestTo:(NSString *)name withMethod:(NSString *)method withParameterKeys:(NSArray *)parameterKeys andParameterValues:(NSArray *)parameterValues isUpload:(BOOL)isUpload
{
	NSDictionary * APIDict;
	if (!(APIDict = APIInfo[name]))
	{
		NSLog(@"%s: key with name not found.", __PRETTY_FUNCTION__);
		return nil;
	}

	if (isUpload)
	{
		return nil;
	}
	else
	{
		NSMutableString * URLString = [NSMutableString stringWithFormat:@"%@%@?api=%@&version=%@&method=%@", [self getAppendedURLWithoutAuth], APIDict[@"path"], APIDict[@"maxVersion"], name, method];
		for (NSString * key in parameterKeys)
		{
			[URLString appendString:[NSString stringWithFormat:@"&%@=%@", key, parameterValues[[parameterKeys indexOfObject:key]]]];
		}
		return [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
	}
}

- (NSMutableURLRequest *)checkForSID:(NSMutableURLRequest *)request
{
	if ([sid length])
	{
		if ([[[request URL] absoluteString] rangeOfString:@"?"].location != NSNotFound)
		{
			[request setURL:[NSURL URLWithString:[[[request URL] absoluteString] stringByAppendingString:[NSString stringWithFormat:@"&_sid=%@", sid]]]];
		}
		else
		{
			[request setHTTPBody:[[[[request HTTPBody] toUTF8String] stringByAppendingString:[NSString stringWithFormat:@"&_sid=%@", sid]] dataUsingEncoding:NSUTF8StringEncoding]];
		}
	}
	else
	{
		storedRequest = request;
		return [[self loginRequest] mutableCopy];
	}
	return request;
}

- (void)login
{
	theConnection = [NSURLConnection connectionWithRequest:[self loginRequest] delegate:self];
}

- (void)logout
{
	[[ConnectionHandler new] sendURLRequest:[self logoutRequest] delegate:self];
	//theConnection = [NSURLConnection connectionWithRequest:[self logoutRequest] delegate:self];
}

- (NSURLRequest *)loginRequest
{
	NSString * key = @"SYNO.API.Auth";
	NSDictionary * APIDict = APIInfo[key];
	return [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@?api=%@&version=%@&method=login&account=%@&passwd=%@&session=DownloadStation&format=sid", [self getAppendedURLWithoutAuth], APIDict[@"path"], key, APIDict[@"maxVersion"], [[self getWebDataForKey:@"username"] orSome:@""], [[self getWebDataForKey:@"password"] orSome:@""]]]];
}

- (NSURLRequest *)logoutRequest
{
	NSString * key = @"SYNO.API.Auth";
	NSDictionary * APIDict = APIInfo[key];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@?api=%@&version=%@&method=logout&session=DownloadStation&_sid=%@", [self getAppendedURLWithoutAuth], APIDict[@"path"], key, APIDict[@"maxVersion"], sid]]];
	[request setTimeoutInterval:2];
	return request;
}

- (void)becameActive
{
	theConnection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@query.cgi?api=SYNO.API.Info&version=1&method=query&query=SYNO.API.Auth,SYNO.API.Info,SYNO.DownloadStation.Task", self.getAppendedURLWithoutAuth]]] delegate:self];
}

- (void)becameIdle
{
	[self logout];
	sid = nil;
}

- (void)willExit
{
	[NSURLConnection sendSynchronousRequest:[self logoutRequest] returningResponse:nil error:nil];
}

- (NSMutableURLRequest *)checkTorrentJobs
{
	NSString * key = @"SYNO.DownloadStation.Task";
	NSDictionary * APIDict = APIInfo[key];
	if ([sid length])
	{
		return [self checkForSID:[NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@?api=%@&version=%@&method=list&additional=detail,transfer,file", [self getAppendedURLWithoutAuth], APIDict[@"path"], key, APIDict[@"maxVersion"]]]]];
	}
	return nil;
}

- (id)getTorrentJobs
{
	id JSON = [NSJSONSerialization JSONObjectWithData:self.jobsData options:0 error:nil];

	if ([JSON respondsToSelector:@selector(objectForKey:)])
	{
		if ([JSON[@"data"] respondsToSelector:@selector(objectForKey:)])
		{
			if ([[JSON[@"data"] allKeys] containsObject:@"tasks"])
			{
				return JSON[@"data"][@"tasks"];
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
		NSNumber * percentDone = @0;
		if ([dict[@"additional"][@"transfer"][@"size_downloaded"] doubleValue] && [dict[@"size"] doubleValue])
		{
			percentDone = @([dict[@"additional"][@"transfer"][@"size_downloaded"] doubleValue] / [dict[@"size"] doubleValue]);
		}
		NSString * ETA = @"";
		if ([dict[@"additional"][@"transfer"][@"speed_download"] integerValue] && ![percentDone isEqual:[[self class] completeNumber]])
		{
			ETA = [@(([dict[@"size"] integerValue] - [dict[@"additional"][@"transfer"][@"size_downloaded"] integerValue]) / [dict[@"additional"][@"transfer"][@"speed_download"] integerValue]) ETAString];
		}
		NSNumber * ratio = @0;
		if ([dict[@"additional"][@"transfer"][@"size_downloaded"] doubleValue])
		{
			ratio = @([dict[@"additional"][@"transfer"][@"size_uploaded"] doubleValue] / [dict[@"additional"][@"transfer"][@"size_downloaded"] doubleValue]);
		}
		[self insertTorrentJobsDictWithArray:@[dict[@"id"], dict[@"title"], percentDone, [dict[@"status"] sentenceParsedString], [dict[@"additional"][@"transfer"][@"speed_download"] transferRateString], [dict[@"additional"][@"transfer"][@"speed_upload"] transferRateString], ETA, [dict[@"additional"][@"transfer"][@"size_downloaded"] sizeString], [dict[@"additional"][@"transfer"][@"size_uploaded"] sizeString], [dict[@"size"] toNumber], dict[@"additional"][@"detail"][@"connected_leechers"], dict[@"additional"][@"detail"][@"connected_seeders"], dict[@"additional"][@"transfer"][@"speed_download"], dict[@"additional"][@"transfer"][@"speed_upload"], ratio] intoDict:tempJobs];
	}
	return tempJobs;
}

- (NSString *)getUserFriendlyAppendString
{
	return @"";
}

- (NSString *)getURLAppendString
{
	return @"/webapi/";
}

- (BOOL)receivedSuccessConditional:(NSData *)response
{
    return [[NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingAllowFragments error:nil][@"success"] isEqual:@YES];
}

- (NSURLRequest *)virtualHandleMagnetLink:(NSString *)magnetLink
{
	NSString * key = @"SYNO.DownloadStation.Task";
	NSDictionary * APIDict = APIInfo[key];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self getAppendedURLWithoutAuth], APIDict[@"path"]]]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[[NSString stringWithFormat:@"api=%@&version=%@&method=create&uri=%@&username=%@&password=%@", key, APIDict[@"maxVersion"], [[magnetLink stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] encodeAmpersands], [[self getWebDataForKey:@"username"] orSome:@""], [[self getWebDataForKey:@"password"] orSome:@""]] dataUsingEncoding:NSUTF8StringEncoding]];
	
	return [self checkForSID:request];
}

- (NSURLRequest *)virtualHandleTorrentFile:(NSData *)fileData withURL:(NSURL *)fileURL
{
	return [self virtualHandleMagnetLink:fileData.magnetLink];
}

- (NSMutableURLRequest *)HTTPRequestWithMethod:(NSString *)method andHash:(NSString *)hash
{
	NSString * key = @"SYNO.DownloadStation.Task";
	NSDictionary * APIDict = APIInfo[key];
	return [self checkForSID:[NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@?api=SYNO.DownloadStation.Task&version=%@&method=%@&id=%@", [self getAppendedURLWithoutAuth], APIDict[@"path"], APIDict[@"maxVersion"], method, hash.lowercaseString]]]];
}

- (NSURLRequest *)virtualPauseTorrent:(NSString *)hash
{
	return [self HTTPRequestWithMethod:@"pause" andHash:hash];
}

- (NSURLRequest *)virtualResumeTorrent:(NSString *)hash
{
	return [self HTTPRequestWithMethod:@"resume" andHash:hash];
}

- (void)pauseAllTorrents
{
	for (NSString * hash in self.getJobsDict.allKeys)
	{
		theConnection = [NSURLConnection connectionWithRequest:[self virtualPauseTorrent:hash] delegate:self];
	}
}

- (void)resumeAllTorrents
{
	for (NSString * hash in self.getJobsDict.allKeys)
	{
		theConnection = [NSURLConnection connectionWithRequest:[self virtualResumeTorrent:hash] delegate:self];
	}
}

- (NSURLRequest *)virtualRemoveTorrent:(NSString *)hash removeData:(BOOL)removeData
{
	NSString * key = @"SYNO.DownloadStation.Task";
	NSDictionary * APIDict = APIInfo[key];
	return [self checkForSID:[NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@?api=%@&version=%@&method=%@&id=%@&force_complete=%@", [self getAppendedURLWithoutAuth], APIDict[@"path"], key, APIDict[@"maxVersion"], @"delete", [hash lowercaseString], @"false"]]]];
}

- (NSString *)parseTorrentFailure:(NSData *)response
{
	NSDictionary * responseDict = [NSJSONSerialization JSONObjectWithData:response options:0 error:nil];
	if ([[NSSet setWithArray:responseDict.allKeys] containsObject:@"error_detail"])
	{
		return [responseDict[@"error_detail"] sentenceParsedString];
	}

	switch ([responseDict[@"error"][@"code"] intValue])
	{
		case 100:
			return @"Unknown error";
			break;
		case 101:
			return @"Invalid parameter";
			break;
		case 102:
			return @"The requested API does not exist";
			break;
		case 103:
			return @"The requested method does not exist";
			break;
		case 104:
			return @"The requested version does not support the functionality";
			break;
		case 105:
			return @"The logged in session does not have permission";
			break;
		case 106:
			return @"Session timeout";
			break;
		case 107:
			return @"Session interrupted by duplicate login";
			break;
		case 400:
			return @"No such account or incorrect password";
			break;
		case 401:
			return @"Guest account disabled";
			break;
		case 402:
			return @"Account disabled";
			break;
		case 403:
			return @"Wrong password";
			break;
		case 404:
			return @"Permission denied";
			break;
		default:
			return @"Non-documented error";
	}
}

+ (NSString *)defaultPort
{
	return @"5000";
}

- (BOOL)supportsEraseChoice
{
	return NO;
}

+ (BOOL)supportsRelativePath
{
	return YES;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if (storedRequest)
	{
		[super connection:connection didFailWithError:error];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSError * error = nil;
	responseData = [[[[responseData toUTF8String] stringByReplacingOccurrencesOfString:@"\n" withString:@""] dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
	NSDictionary * responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
	
	if ([NSJSONSerialization isValidJSONObject:responseDict])
	{
		if ([[NSSet setWithArray:responseDict.allKeys] containsObject:@"data"] && [responseDict[@"data"] respondsToSelector:@selector(objectForKey:)])
		{
			if ([[responseDict[@"data"] allKeys] containsObject:@"SYNO.API.Auth"])
			{
				APIInfo = [responseDict[@"data"] mutableCopy];
				[self login];
			}
			else if ([[responseDict[@"data"] allKeys] containsObject:@"sid"])
			{
				sid = responseDict[@"data"][@"sid"];
				if (storedRequest)
				{
					responseData = [NSMutableData new];
					theConnection = [NSURLConnection connectionWithRequest:[self checkForSID:storedRequest] delegate:self];
					storedRequest = nil;
				}
			}
			responseData = [NSMutableData new];
			return;
		}
		else if ([responseDict[@"error"][@"code"] intValue] == 106 || [responseDict[@"error"][@"code"] intValue] == 107)
		{
			[self login];
		}
	}

	[super connectionDidFinishLoading:connection];
}

+ (BOOL)supportsDirectoryChoice
{
	return NO;
}

@end
