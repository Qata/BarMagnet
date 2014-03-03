//
//  rTorrentXMLRPC.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 1/03/2014.
//  Copyright (c) 2014 Carlo Tortorella. All rights reserved.
//

#import "rTorrentXMLRPC.h"
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

@interface rTorrentXMLRPC () <NSXMLParserDelegate>
@property (nonatomic, strong) NSXMLParser * parser;
@property (nonatomic, strong) NSArray * keys;
@property (nonatomic, strong) NSMutableArray * values;
@end

@implementation rTorrentXMLRPC

- (NSMutableURLRequest *)RPCRequestWithMethodName:(NSString *)methodName view:(NSString *)view andParams:(NSArray *)params;
{
	NSMutableString * RPCString = [NSMutableString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><methodCall><methodName>%@</methodName><params>", methodName];
	if (view)
	{
		[RPCString appendFormat:@"<param><value><string>%@</string></value></param>", view];
	}
    for (id param in params)
    {
		NSString * type = @"string";
		if ([param isKindOfClass:[NSNumber class]])
		{
			type = @"i8";
		}
        [RPCString appendFormat:@"<param><value><%@>%@</%@></value></param>", type, param, type];
    }
	[RPCString appendString:@"</params></methodCall>"];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.getAppendedURL]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[RPCString dataUsingEncoding:NSASCIIStringEncoding]];
	return request;
}

+ (NSString *)name
{
	return @"rTorrent XMLRPC";
}

+ (NSNumber *)completeNumber
{
    return @1;
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	self.values = NSMutableArray.new;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"data"])
	{
		[self.values addObject:NSMutableArray.new];
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if ([string rangeOfString:@"\n"].location == NSNotFound)
	{
		[self.values.lastObject addObject:string];
	}
}

- (NSMutableURLRequest *)checkTorrentJobs
{
	self.keys = @[@"d.get_hash=", @"d.get_state=", @"d.get_name=", @"d.get_down_rate=", @"d.get_up_rate=", @"d.get_bytes_done=", @"d.get_up_total=", @"d.get_size_bytes=", @"d.get_peers_accounted=", @"d.get_peers_complete=", @"d.is_open=", @"d.get_creation_date="];
	return [self RPCRequestWithMethodName:@"d.multicall" view:@"main" andParams:self.keys];
}

- (id)getTorrentJobs
{
	self.parser = [NSXMLParser.alloc initWithData:jobsData];
	self.parser.delegate = self;
	[self.parser parse];

	NSMutableArray * retVal = NSMutableArray.new;
	for (NSArray * array in self.values)
	{
		if (array.count == self.keys.count)
		{
			[retVal addObject:[NSDictionary dictionaryWithObjects:array forKeys:self.keys]];
		}
	}
	return retVal;
}

- (NSDictionary *)virtualHandleTorrentJobs
{
	NSMutableDictionary * tempJobs = [NSMutableDictionary new];
	for (NSDictionary * dict in [self getTorrentJobs])
	{
		NSNumber * percentDone = @0;
		if ([dict[@"d.get_bytes_done="] doubleValue] && [dict[@"d.get_size_bytes="] doubleValue])
		{
			percentDone = @([dict[@"d.get_bytes_done="] doubleValue] / [dict[@"d.get_size_bytes="] doubleValue]);
		}
		NSString * status = @"";
		switch ([dict[@"d.get_state="] intValue])
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
		if ([dict[@"d.get_down_rate="] integerValue] && ![percentDone isEqual:[[self class] completeNumber]])
		{
			ETA = [@(([dict[@"d.get_size_bytes="] integerValue] - [dict[@"d.get_bytes_done="] integerValue]) / [dict[@"d.get_down_rate="] integerValue]) ETAString];
		}
		[self insertTorrentJobsDictWithArray:@[dict[@"d.get_hash="], dict[@"d.get_name="], percentDone, status, [dict[@"d.get_down_rate="] transferRateString], [dict[@"d.get_up_rate="] transferRateString], ETA, [dict[@"d.get_bytes_done="] sizeString], [dict[@"d.get_up_total="] sizeString], [dict[@"d.get_size_bytes="] toNumber], dict[@"d.get_peers_accounted="], dict[@"d.get_peers_complete="], dict[@"d.get_down_rate="], dict[@"d.get_up_rate="], @([dict[@"d.get_bytes_done="] doubleValue] ? [dict[@"d.get_up_total="] doubleValue] / [dict[@"d.get_bytes_done="] doubleValue] : 0), dict[@"d.get_creation_date="]] intoDict:tempJobs];
	}
	return tempJobs;
}

- (BOOL)isValidJobsData:(NSData *)data
{
	return [data.toUTF8String rangeOfString:@"<fault>"].location == NSNotFound && [data.toUTF8String rangeOfString:@"<title>404 Not Found</title>"].location == NSNotFound;
}

- (NSURLRequest *)virtualHandleMagnetLink:(NSString *)magnetLink
{
	return [self RPCRequestWithMethodName:@"load_start" view:nil andParams:@[[magnetLink componentsSeparatedByString:@"&"].firstObject]];
}

- (NSURLRequest *)virtualHandleTorrentFile:(NSData *)fileData withURL:(NSURL *)fileURL
{
	return [self RPCRequestWithMethodName:@"load_start" view:nil andParams:@[fileURL]];
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
	return [response.toUTF8String rangeOfString:@"<fault>"].location == NSNotFound && [response.toUTF8String rangeOfString:@"<title>404 Not Found</title>"].location == NSNotFound;
}

- (NSURLRequest *)virtualPauseTorrent:(NSString *)hash
{
	return [self RPCRequestWithMethodName:@"d.stop" view:nil andParams:@[hash]];
}

- (NSURLRequest *)virtualResumeTorrent:(NSString *)hash
{
	return [self RPCRequestWithMethodName:@"d.start" view:nil andParams:@[hash]];
}

- (NSURLRequest *)virtualRemoveTorrent:(NSString *)hash removeData:(BOOL)removeData
{
	return [self RPCRequestWithMethodName:@"d.erase" view:nil andParams:@[hash]];
}

- (NSURLRequest *)virtualPauseAllTorrents
{
	for (NSString * hash in self.getJobsDict.allKeys)
	{
		if (hash != self.getJobsDict.allKeys.lastObject)
		{
			[NSURLConnection connectionWithRequest:[self RPCRequestWithMethodName:@"d.stop" view:nil andParams:@[hash]] delegate:self];
		}
	}
	return [self RPCRequestWithMethodName:@"d.stop" view:nil andParams:@[self.getJobsDict.allKeys.lastObject]];
}

- (NSURLRequest *)virtualResumeAllTorrents
{
	for (NSString * hash in self.getJobsDict.allKeys)
	{
		if (hash != self.getJobsDict.allKeys.lastObject)
		{
			[NSURLConnection connectionWithRequest:[self RPCRequestWithMethodName:@"d.start" view:nil andParams:@[hash]] delegate:self];
		}
	}
	return [self RPCRequestWithMethodName:@"d.start" view:nil andParams:@[self.getJobsDict.allKeys.lastObject]];
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
