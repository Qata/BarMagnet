//
//  NSData+BEncode.m
//  Bar Magnet
//
//  Created by Charlotte Tortorella on 17/04/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#import "NSData+BEncode.h"
#import "NSBencodeSerialization.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSData (BEncode)

+ (NSString *)torrentHashFromFileWithPath:(NSString *)filePath
{
	return [self torrentHashFromFile:[NSFileManager.defaultManager contentsAtPath:filePath]];
}

+ (NSString *) torrentHashFromFileWithURL:(NSURL *)filePath
{
	return [self torrentHashFromFileWithPath:filePath.path];
}

+ (NSString *)torrentHashFromFile:(NSData *)file
{
	unsigned char hashBytes[CC_SHA1_DIGEST_LENGTH];
	NSError * error = nil;
	NSData * bencoded = [NSBencodeSerialization dataWithBencodedObject:[NSBencodeSerialization bencodedObjectWithData:file error:&error][@"info"] error:&error];
	if (!error && CC_SHA1(bencoded.bytes, (unsigned)bencoded.length, hashBytes))
	{
		NSMutableString * output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
		for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
		{
			[output appendFormat:@"%02X", hashBytes[i]];
		}
		return output;
	}
	return nil;
}

- (NSString *)torrentHash
{
	unsigned char hashBytes[CC_SHA1_DIGEST_LENGTH];
	NSError * error = nil;
	NSData * bencoded = [NSBencodeSerialization dataWithBencodedObject:[NSBencodeSerialization bencodedObjectWithData:self error:&error][@"info"] error:&error];
	if (!error && CC_SHA1(bencoded.bytes, (unsigned)bencoded.length, hashBytes))
	{
		NSMutableString * output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
		for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
		{
			[output appendFormat:@"%02X", hashBytes[i]];
		}
		return output;
	}
	return nil;
}

- (NSString *)torrentHashWithError:(NSError **)error
{
	NSError * lerror = nil;
	id bdecoded = [NSBencodeSerialization bencodedObjectWithData:self error:&lerror];
	if (!lerror && [bdecoded respondsToSelector:@selector(objectForKey:)])
	{
		unsigned char hashBytes[CC_SHA1_DIGEST_LENGTH];

		NSData * bencoded = [NSBencodeSerialization dataWithBencodedObject:bdecoded[@"info"] error:&lerror];
		if (!lerror && CC_SHA1(bencoded.bytes, (unsigned)bencoded.length, hashBytes))
		{
			NSMutableString * output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
			for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
			{
				[output appendFormat:@"%02X", hashBytes[i]];
			}
			return output;
		}
	}

	if (error)
	{
		*error = lerror;
	}

	return nil;
}

- (NSString *)magnetLink
{
	NSError * error = nil;
	NSDictionary * torrentArgsDict = [NSBencodeSerialization bencodedObjectWithData:self error:&error];
	if (!error)
	{
		NSMutableArray * trackers = [NSMutableArray new];
		if ([torrentArgsDict isKindOfClass:NSDictionary.class])
		{
			if ([torrentArgsDict[@"announce-list"] isKindOfClass:NSArray.class])
			{
				for (NSArray * tracker in torrentArgsDict[@"announce-list"])
				{
					if ([tracker isKindOfClass:NSArray.class] && [tracker count])
					{
						for (NSString * trackerString in tracker)
						{
							[trackers addObject:[NSString stringWithFormat:@"tr=%@", [[trackerString stringByReplacingOccurrencesOfString:@":" withString:@"%3A"] stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"]]];
						}
					}
				}
			}
		}
		return [NSString stringWithFormat:@"magnet:?xt=urn:btih:%@&dn=%@%@", self.torrentHash, [self.torrentName orSome:@""], [trackers count] ? [NSString stringWithFormat:@"&%@", [trackers componentsJoinedByString:@"&"]] : @""];
	}
	return nil;
}

+ (NSOption *)torrentNameFromFileWithPath:(NSString *)filePath
{
	return filePath ? [self torrentNameFromFile:[[NSFileManager defaultManager] contentsAtPath:filePath]] : [NSOption none];
}

+ (NSOption *)torrentNameFromFileWithURL:(NSURL *)filePath
{
	return filePath ? [self torrentNameFromFile:[[NSFileManager defaultManager] contentsAtPath:filePath.path]] : [NSOption none];
}

+ (NSOption *)torrentNameFromFile:(NSData *)file
{
	return file.torrentName;
}

- (NSOption *)torrentName
{
	NSError * error = nil;
	id dict = [NSBencodeSerialization bencodedObjectWithData:self error:&error];
	if (!error && [dict respondsToSelector:@selector(allKeys)])
	{
		id info = dict[@"info"];
		if ([info respondsToSelector:@selector(allKeys)])
		{
			if ([[info allKeys] containsObject:@"name.utf-8"])
			{
				return [NSOption fromNil:[NSString stringWithFormat:@"%@", info[@"name.utf-8"]]];
			}
			else if ([[info allKeys] containsObject:@"name"])
			{
				return [NSOption fromNil:[NSString stringWithFormat:@"%@", info[@"name"]]];
			}
		}
	}
	return [NSOption none];
}

@end
