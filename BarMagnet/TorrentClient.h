//
//  TorrentClient.h
//  Bar Magnet
//
//  Created by Carlo Tortorella on 25/03/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#pragma once
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
@class TorrentFileHandler;
#endif

enum
{
	WCS_ALL_FIELDS_HEIGHT = 165,
	WCS_RELATIVE_PATH_HEIGHT = 245
};

@interface TorrentClient : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{
	NSDictionary * previousJobs;
	NSMutableDictionary * torrentJobsDict;
	NSMutableArray * notificationJobs;
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	TorrentFileHandler * torrentFileHandler;
	UIViewController * notificationViewController;
#endif
	NSString * token;
	NSString * torrentName;
	NSString * hashString;
	NSMutableData * responseData;
	NSURLConnection * theConnection;
	NSMutableData * jobsData;
	BOOL hostOnline;
}
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
@property (nonatomic, strong) UIViewController * defaultViewController;
#endif
@property (nonatomic, strong, setter = setTemporaryDeletedJobs:, getter = getTemporaryDeletedJobs) NSMutableDictionary * temporaryDeletedJobs;
- (void)addTemporaryDeletedJob:(NSUInteger)object forKey:(NSString *)key;

//-------Virtual functions-------
+ (NSString *)name;
+ (NSNumber *)completeNumber;
- (BOOL)isValidJobsData:(NSData *)data;
- (NSMutableURLRequest *)checkTorrentJobs;
+ (NSString *)defaultPort;
+ (BOOL)supportsRelativePath;
- (NSInteger)windowChangeHeightValue;
- (void)becameActive;
- (void)becameIdle;
- (void)willExit;
- (BOOL)supportsMulticall;
+ (BOOL)supportsDirectoryChoice;
- (BOOL)supportsAddedDate;
- (NSString *)parseTorrentFailure:(NSData *)response;
//-------------------------------

- (id)noJobImplementation;
- (void)handleMagnetLink:(NSString *)magnetLink;
- (void)handleTorrentFile:(NSString *)filePath;
- (void)handleTorrentURL:(NSURL *)fileURL;
- (void)handleTorrentData:(NSData *)data withURL:(NSURL *)fileURL;
- (void)pauseTorrent:(NSString *)hash;
- (void)resumeTorrent:(NSString *)hash;
- (void)removeTorrent:(NSString *)hash removeData:(BOOL)removeData;
- (void)pauseAllTorrents;
- (void)resumeAllTorrents;
- (void)handleTorrentJobs;
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
- (void)showNotification:(UIViewController *)viewController;
#endif
- (void)insertTorrentJobsDictWithArray:(NSArray *)array intoDict:(NSMutableDictionary *)dict;

- (NSString *)getBaseURL;
- (NSString *)getHost;
- (NSString *)getHostWithPort;
- (NSString *)getAppendedURL;
- (NSString *)getHyperTextString;
- (NSString *)getAppendedURLWithoutAuth;
- (NSString *)getUserFriendlyAppendedURL;
- (NSOption *)getWebDataForKey:(NSString *)key;
- (NSString *)parseTorrentFileName:(NSString *)fileName;
- (void)setJobsData:(NSData *)data;
- (void)setJobsDict:(NSMutableDictionary *)dict;
- (void)setHostOnline:(BOOL)boolean;
- (BOOL)isHostOnline;
- (BOOL)supportsEraseChoice;
- (NSDictionary *)getJobsDict;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
@end
