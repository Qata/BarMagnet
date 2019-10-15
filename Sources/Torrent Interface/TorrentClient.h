//
//  TorrentClient.h
//  Bar Magnet
//
//  Created by Charlotte Tortorella on 25/03/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#pragma once
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
@class TorrentFileHandler;
#endif

enum { WCS_ALL_FIELDS_HEIGHT = 165,
       WCS_RELATIVE_PATH_HEIGHT = 245 };

@interface TorrentClient : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate> {
    TorrentFileHandler *torrentFileHandler;
    NSDictionary *previousJobs;
    NSMutableDictionary *torrentJobsDict;
    NSMutableArray *notificationJobs;
    NSString *torrentName;
    NSString *hashString;
    NSMutableData *responseData;
    NSURLConnection *theConnection;
    BOOL hostOnline;
}

@property(nonatomic, strong) NSData *jobsData;
@property(nonatomic, strong, setter=setTemporaryDeletedJobs:, getter=getTemporaryDeletedJobs) NSMutableDictionary *temporaryDeletedJobs;
@property(nonatomic, weak, setter=showNotification:) UIViewController *notificationViewController;
- (void)addTemporaryDeletedJob:(NSUInteger)object forKey:(NSString *)key;

//-------Virtual functions-------
+ (NSString *)name;
+ (NSNumber *)completeNumber;
+ (NSString *)defaultPort;
+ (BOOL)supportsRelativePath;
+ (BOOL)supportsLabels;
+ (BOOL)supportsDirectoryChoice;
+ (BOOL)isSeedbox;
+ (BOOL)hasQR;
+ (BOOL)showsUsername;
- (BOOL)isValidJobsData:(NSData *)data;
- (NSMutableURLRequest *)checkTorrentJobs;
- (NSInteger)windowChangeHeightValue;
- (void)becameActive;
- (void)becameIdle;
- (void)willExit;
- (BOOL)supportsMulticall;
- (BOOL)supportsAddedDate;
- (BOOL)supportsCompletedDate;
- (NSString *)parseTorrentFailure:(NSData *)response;
//-------------------------------

- (id)noJobImplementation;
- (void)handleMagnetLink:(NSString *)magnetLink;
- (void)handleTorrentFile:(NSURL *)url;
- (void)handleTorrentURL:(NSURL *)fileURL;
- (void)handleTorrentData:(NSData *)data withURL:(NSURL *)fileURL;
- (void)pauseTorrent:(NSString *)hash;
- (void)resumeTorrent:(NSString *)hash;
- (void)removeTorrent:(NSString *)hash removeData:(BOOL)removeData;
- (void)pauseAllTorrents;
- (void)resumeAllTorrents;
- (void)handleTorrentJobs;
- (void)showSuccessMessage;
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
- (void)setJobsDict:(NSMutableDictionary *)dict;
- (void)setHostOnline:(BOOL)boolean;
- (BOOL)isHostOnline;
- (BOOL)supportsEraseChoice;
- (NSDictionary *)getJobsDict;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
@end
