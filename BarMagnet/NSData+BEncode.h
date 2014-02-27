//
//  NSData+BEncode.h
//  Bar Magnet
//
//  Created by Carlo Tortorella on 17/04/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//
#import "NSOption.h"

@interface NSData (BEncode)

+ (NSString *)torrentHashFromFileWithPath:(NSString *)filePath;
+ (NSString *)torrentHashFromFileWithURL:(NSURL *)filePath;
+ (NSString *)torrentHashFromFile:(NSData *)file;
- (NSString *)torrentHashWithError:(NSError **)error;

+ (NSOption *)torrentNameFromFileWithPath:(NSString *)filePath;
+ (NSOption *)torrentNameFromFileWithURL:(NSURL *)filePath;
+ (NSOption *)torrentNameFromFile:(NSData *)file;
- (NSString *)magnetLink;
- (NSOption *)torrentName;
- (NSString *)torrentHash;

@end