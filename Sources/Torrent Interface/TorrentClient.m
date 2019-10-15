//
//  TorrentClient.m
//  Bar Magnet
//
//  Created by Charlotte Tortorella on 25/03/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#if !TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
#import "NotificationHandler.h"
#else
#import "TSMessage.h"
#import "TorrentFileHandler.h"
#endif
#import "FileHandler.h"
#import "NSBencodeSerialization.h"
#import "NSData+BEncode.h"
#import "TorrentClient.h"
@import UserNotifications;

#define TSDURATION 1.85

@implementation TorrentClient

- (id)init {
    if (self = [super init]) {
        torrentJobsDict = [NSMutableDictionary new];
        responseData = [NSMutableData new];
        self.jobsData = [NSMutableData new];
        torrentFileHandler = [TorrentFileHandler new];
        _temporaryDeletedJobs = [NSMutableDictionary new];
    }
    return self;
}

+ (NSString *)name {
    NSLog(@"Incomplete implementation of: %s", __PRETTY_FUNCTION__);
    return nil;
}

+ (NSNumber *)completeNumber {
    NSLog(@"Incomplete implementation of: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (BOOL)isValidJobsData:(NSData *)data {
    return NO;
}

- (NSMutableURLRequest *)checkTorrentJobs {
    return [self noJobImplementation];
}

- (id)getTorrentJobs {
    NSLog(@"Incomplete implementation of: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSString *)getUserFriendlyAppendString {
    NSLog(@"Incomplete implementation of: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSString *)getURLAppendString {
    NSLog(@"Incomplete implementation of: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (BOOL)receivedSuccessConditional:(NSData *)response {
    NSLog(@"Incomplete implementation of: %s", __PRETTY_FUNCTION__);
    return NO;
}

- (NSString *)parseTorrentFailure:(NSData *)response {
    NSLog(@"Incomplete implementation of: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSURLRequest *)virtualHandleMagnetLink:(NSString *)magnetLink {
    NSLog(@"Incomplete implementation of: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSURLRequest *)virtualHandleTorrentFile:(NSData *)fileData withURL:(NSURL *)fileURL {
    NSLog(@"Incomplete implementation of: %s", __PRETTY_FUNCTION__);
    return nil;
}

+ (NSString *)defaultPort {
    NSLog(@"Incomplete implementation of: %s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSURLRequest *)virtualPauseTorrent:(NSString *)hash {
    return nil;
}

- (NSURLRequest *)virtualResumeTorrent:(NSString *)hash {
    return nil;
}

- (NSURLRequest *)virtualRemoveTorrent:(NSString *)hash removeData:(BOOL)removeData {
    return nil;
}

- (NSURLRequest *)virtualPauseAllTorrents {
    return nil;
}

- (NSURLRequest *)virtualResumeAllTorrents {
    return nil;
}

- (NSURLRequest *)virtualRemoveAllTorrentsWithData:(BOOL)removeData {
    return nil;
}

- (NSDictionary *)virtualHandleTorrentJobs {
    return nil;
}

- (void)becameActive {
}

- (void)becameIdle {
}

- (void)willExit {
}

- (BOOL)supportsMulticall {
    return YES;
}

- (NSInteger)windowChangeHeightValue {
    return WCS_RELATIVE_PATH_HEIGHT;
}

+ (BOOL)supportsRelativePath {
    return NO;
}

+ (BOOL)supportsLabels {
    return NO;
}

- (id)noJobImplementation {
    return torrentJobsDict = nil;
}

- (void)insertTorrentJobsDictWithArray:(NSArray *)array intoDict:(NSMutableDictionary *)dict {
    NSMutableDictionary *torrentDict = [NSMutableDictionary new];

    for (id item in array) {
        if (!item) {
            return;
        }
    }
    switch ([array count]) {
    default:
        [torrentDict setObject:array[16] forKey:@"dateDone"];
    case 16:
        [torrentDict setObject:array[15] forKey:@"dateAdded"];
    case 15:
        [torrentDict setObject:array[14] forKey:@"ratio"];
    case 14:
        [torrentDict setObject:array[13] forKey:@"rawUploadSpeed"];
    case 13:
        [torrentDict setObject:array[12] forKey:@"rawDownloadSpeed"];
    case 12:
        [torrentDict setObject:[array[11] description] forKey:@"seedsConnected"];
    case 11:
        [torrentDict setObject:[array[10] description] forKey:@"peersConnected"];
    case 10:
        [torrentDict setObject:array[9] forKey:@"size"];
    case 9:
        [torrentDict setObject:array[8] forKey:@"uploaded"];
    case 8:
        [torrentDict setObject:array[7] forKey:@"downloaded"];
    case 7:
        [torrentDict setObject:array[6] forKey:@"ETA"];
    case 6:
        [torrentDict setObject:array[5] forKey:@"uploadSpeed"];
    case 5:
        [torrentDict setObject:array[4] forKey:@"downloadSpeed"];
    case 4:
        [torrentDict setObject:array[3] forKey:@"status"];
    case 3:
        [torrentDict setObject:array[2] forKey:@"progress"];
    case 2:
        [torrentDict setObject:array[1] forKey:@"name"];
    case 1:
        [torrentDict setObject:[array[0] uppercaseString] forKey:@"hash"];
        break;
    case 0:
        return;
    }

    [dict setObject:torrentDict forKey:[array[0] uppercaseString]];
}

- (void)handleMagnetLink:(NSString *)magnetLink {
    hashString = [[magnetLink getStringBetween:@"btih:" andString:@"&"] uppercaseString];
    if (![[NSSet setWithArray:torrentJobsDict.allKeys] containsObject:hashString]) {
        torrentName = [StringHandler
            parseNotification:[StringHandler parseURLAsHumanReadable:[NSString stringWithFormat:@"\"%@\"", [magnetLink getStringBetween:@"dn=" andString:@"&"]]]];
        theConnection = [NSURLConnection connectionWithRequest:[self virtualHandleMagnetLink:magnetLink] delegate:self];
    } else {
        if (self.notificationViewController) {
            [TSMessage showNotificationInViewController:self.notificationViewController
                                                  title:@"Unable to add torrent"
                                               subtitle:@"Duplicate Torrent"
                                                  image:nil
                                                   type:TSMessageNotificationTypeError
                                               duration:TSDURATION
                                               callback:nil
                                            buttonTitle:nil
                                         buttonCallback:nil
                                             atPosition:TSMessageNotificationPositionTop
                                   canBeDismissedByUser:YES];
        } else {
            [TSMessage showNotificationWithTitle:@"Unable to add torrent" subtitle:@"Duplicate Torrent" type:TSMessageNotificationTypeError];
        }
    }
}

- (void)handleTorrentFile:(NSURL *)url {
    [self handleTorrentData:[[NSFileManager defaultManager] contentsAtPath:url.absoluteString] withURL:nil];
}

- (void)handleTorrentURL:(NSURL *)fileURL {
    [torrentFileHandler downloadTorrentFile:fileURL withDelegate:self];
}

- (void)handleTorrentData:(NSData *)data withURL:(NSURL *)fileURL {
    hashString = [[NSData torrentHashFromFile:data] uppercaseString];
    if (![[NSSet setWithArray:torrentJobsDict.allKeys] containsObject:hashString]) {
        torrentName = [StringHandler parseNotification:[[data torrentName] orSome:@"Torrent"]];
        theConnection = [NSURLConnection connectionWithRequest:[self virtualHandleTorrentFile:data withURL:fileURL] delegate:self];
    } else {
        if (self.notificationViewController) {
            [TSMessage showNotificationInViewController:self.notificationViewController
                                                  title:@"Unable to add torrent"
                                               subtitle:@"Duplicate Torrent"
                                                  image:nil
                                                   type:TSMessageNotificationTypeError
                                               duration:TSDURATION
                                               callback:nil
                                            buttonTitle:nil
                                         buttonCallback:nil
                                             atPosition:TSMessageNotificationPositionTop
                                   canBeDismissedByUser:YES];
        } else {
            [TSMessage showNotificationWithTitle:@"Unable to add torrent" subtitle:@"Duplicate Torrent" type:TSMessageNotificationTypeError];
        }
    }
}

- (void)pauseTorrent:(NSString *)hash {
    theConnection = [NSURLConnection connectionWithRequest:[self virtualPauseTorrent:hash] delegate:self];
}

- (void)resumeTorrent:(NSString *)hash {
    theConnection = [NSURLConnection connectionWithRequest:[self virtualResumeTorrent:hash] delegate:self];
}

- (void)removeTorrent:(NSString *)hash removeData:(BOOL)removeData {
    theConnection = [NSURLConnection connectionWithRequest:[self virtualRemoveTorrent:hash removeData:removeData] delegate:self];
}

- (void)pauseAllTorrents {
    theConnection = [NSURLConnection connectionWithRequest:[self virtualPauseAllTorrents] delegate:self];
}

- (void)resumeAllTorrents {
    theConnection = [NSURLConnection connectionWithRequest:[self virtualResumeAllTorrents] delegate:self];
}

- (void)addTemporaryDeletedJob:(NSUInteger)object forKey:(NSString *)key {
    if (object) {
        [_temporaryDeletedJobs setObject:@(object) forKey:key];
        [torrentJobsDict removeObjectForKey:key];
    }
}

- (void)handleTorrentJobs {
    previousJobs = [NSDictionary dictionaryWithDictionary:torrentJobsDict];
    torrentJobsDict = [NSMutableDictionary dictionaryWithDictionary:self.virtualHandleTorrentJobs];

    for (NSString *hash in [_temporaryDeletedJobs allKeys]) {
        if ([_temporaryDeletedJobs[hash] integerValue] <= 0 || ![[torrentJobsDict allKeys] containsObject:hash]) {
            [_temporaryDeletedJobs removeObjectForKey:hash];
        } else if ([[torrentJobsDict allKeys] containsObject:hash]) {
            [torrentJobsDict removeObjectForKey:hash];
            [_temporaryDeletedJobs setObject:@([_temporaryDeletedJobs[hash] integerValue] - 1) forKey:hash];
        }
    }

    notificationJobs = [NSMutableArray new];

    for (NSString *key in torrentJobsDict) // The key is the hash string, the object for it is a dictionary described in virtualHandleTorrentJobs
    {
        if ([torrentJobsDict[key] respondsToSelector:@selector(objectForKey:)] && previousJobs.count) {
            if (self.class.completeNumber.integerValue) {
                if ([torrentJobsDict[key][@"progress"] isEqual:[[self class] completeNumber]] &&
                    [previousJobs[key][@"progress"] integerValue] < self.class.completeNumber.integerValue) {
                    [notificationJobs addObject:torrentJobsDict[key][@"name"]];
                }
            }
        }
    }
    
    NSString * title = nil;
    NSString * body = nil;
    switch (notificationJobs.count) {
        case 0:
            break;
        case 1:
            title = @"Download finished";
            body = [NSString stringWithFormat:@"%@ finished downloading", notificationJobs[0]];
            break;
        default:
            title = [NSString stringWithFormat:@"%lu downloads finished", (unsigned long)notificationJobs.count];
            body = [NSString stringWithFormat:@"%@ and %@ finished downloading", [[notificationJobs subarrayWithRange:NSMakeRange(0, notificationJobs.count - 1)] componentsJoinedByString:@", "], notificationJobs.lastObject];
            break;
    }
    
    if (title && body) {
        UNMutableNotificationContent * notificationContent = [UNMutableNotificationContent new];
        notificationContent.title = title;
        notificationContent.body = body;
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:[UNNotificationRequest requestWithIdentifier:@"Notification" content:notificationContent trigger:nil] withCompletionHandler:^(NSError * _Nullable error) {}];
    }
}

- (NSOption *)getWebDataForKey:(NSString *)key {
    NSOption *retVal = [FileHandler.sharedInstance webDataValueForKey:key];
    return retVal;
}

- (NSString *)getBaseURL {
    // Access the data and build the µTorrent URL
    NSString *urlString;
    NSString *port = [[self getWebDataForKey:@"port"] orSome:@"80"];
    NSString *username = [[[self getWebDataForKey:@"username"] orSome:@""] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    NSString *password = [[[self getWebDataForKey:@"password"] orSome:@""] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    NSString *url = [[self getWebDataForKey:@"url"] orSome:@"localhost"];

    url = [url stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    url = [url stringByReplacingOccurrencesOfString:@"https://" withString:@""];

    // Make sure both the username and the password are non-nil values, otherwise the ":" will prevent the URL from loading
    if ([username length] && [password length]) {
        urlString = [NSString stringWithFormat:@"%@%@:%@@%@:%@", [self getHyperTextString], username, password, url, port];
    } else if ([username length] > 0) {
        urlString = [NSString stringWithFormat:@"%@%@@%@:%@", [self getHyperTextString], username, url, port];
    } else {
        urlString = [NSString stringWithFormat:@"%@%@:%@", [self getHyperTextString], url, port];
    }

    return urlString;
}

- (NSString *)getHostWithPort {
    return [NSString stringWithFormat:@"%@:%@", [[self getWebDataForKey:@"url"] orSome:@"localhost"], [[self getWebDataForKey:@"port"] orSome:@""]];
}

- (NSString *)getHost {
    return [[self getWebDataForKey:@"url"] orSome:@"localhost"];
}

- (NSString *)getAppendedURL {
    return [[NSURL URLWithString:self.getBaseURL] URLByAppendingPathComponent:self.getURLAppendString].absoluteString;
}

- (NSString *)getHyperTextString {
    return [NSString stringWithFormat:@"http%@://", [[[FileHandler.sharedInstance webDataValueForKey:@"use_ssl"] orSome:@NO] boolValue] ? @"s" : @""];
}

- (NSString *)getAppendedURLWithoutAuth {
    // Access the data and build the URL
    NSString *url = [[self getWebDataForKey:@"url"] orSome:@"localhost"];
    NSString *port = [[self getWebDataForKey:@"port"] orSome:@"80"];

    url = [url stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    url = [url stringByReplacingOccurrencesOfString:@"https://" withString:@""];
    
    NSLog(@"%@", [NSString stringWithFormat:@"%@%@:%@%@", [self getHyperTextString], url, port, self.getURLAppendString]);

    return [NSString stringWithFormat:@"%@%@:%@%@", [self getHyperTextString], url, port, self.getURLAppendString];
}

- (NSString *)getUserFriendlyAppendedURL {
    // Access the data and build the URL
    NSString *url = [[self getWebDataForKey:@"url"] orSome:@"localhost"];
    NSString *port = [[self getWebDataForKey:@"port"] orSome:@"80"];

    url = [url stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    url = [url stringByReplacingOccurrencesOfString:@"https://" withString:@""];

    if ([port isEqualToString:@"80"]) {
        return
            [[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self getHyperTextString], url]] URLByAppendingPathComponent:self.getUserFriendlyAppendString]
                .absoluteString;
    } else {
        return [[NSURL URLWithString:[NSString stringWithFormat:@"%@%@:%@", [self getHyperTextString], url, port]]
                   URLByAppendingPathComponent:self.getUserFriendlyAppendString]
            .absoluteString;
    }
}

- (NSString *)parseTorrentFileName:(NSString *)fileName {
    NSRange forwardSlashRange;
    forwardSlashRange.location = [fileName rangeOfString:@"/" options:NSBackwardsSearch].location + 1;
    forwardSlashRange.length = [fileName length] - forwardSlashRange.location;
    return [fileName substringWithRange:forwardSlashRange];
}

- (void)setJobsDict:(NSMutableDictionary *)dict {
    torrentJobsDict = dict;
}

- (void)setHostOnline:(BOOL)boolean {
    hostOnline = boolean;
}

- (BOOL)supportsEraseChoice {
    return YES;
}

+ (BOOL)supportsDirectoryChoice {
    return NO;
}

- (BOOL)supportsAddedDate {
    return NO;
}

- (BOOL)supportsCompletedDate {
    return NO;
}

+ (BOOL)isSeedbox {
    return NO;
}

+ (BOOL)hasQR {
    return NO;
}

+ (BOOL)showsUsername {
    return YES;
}

- (BOOL)isHostOnline {
    return hostOnline;
}

- (NSDictionary *)getJobsDict {
    return torrentJobsDict;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [responseData appendData:data];
}

#pragma mark - Notification Handling
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [UIApplication.sharedApplication setNetworkActivityIndicatorVisible:NO];
    NSString *notification;
    NSLog(@"%@, %li", error.description, (long)error.code);

    if (error.code == -1012) {
        notification = @"Incorrect or missing user credentials.";
    } else {
        notification = [error localizedDescription];
    }

    if (self.notificationViewController) {
        [TSMessage showNotificationInViewController:self.notificationViewController
                                              title:@"An error occurred"
                                           subtitle:notification
                                              image:nil
                                               type:TSMessageNotificationTypeError
                                           duration:TSDURATION
                                           callback:nil
                                        buttonTitle:nil
                                     buttonCallback:nil
                                         atPosition:TSMessageNotificationPositionTop
                               canBeDismissedByUser:YES];
    } else {
        [TSMessage showNotificationWithTitle:@"An error occurred" subtitle:notification type:TSMessageNotificationTypeError];
    }
}

- (void)showSuccessMessage {
    if (self.notificationViewController) {
        [TSMessage showNotificationInViewController:self.notificationViewController
                                              title:@"Torrent added successfully"
                                           subtitle:torrentName
                                              image:nil
                                               type:TSMessageNotificationTypeSuccess
                                           duration:TSDURATION
                                           callback:nil
                                        buttonTitle:nil
                                     buttonCallback:nil
                                         atPosition:TSMessageNotificationPositionTop
                               canBeDismissedByUser:YES];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [UIApplication.sharedApplication setNetworkActivityIndicatorVisible:NO];
    if ([self receivedSuccessConditional:responseData]) {
        [self showSuccessMessage];
    } else if ([[responseData toUTF8String] length] > 1) {
        if (self.notificationViewController) {
            [TSMessage showNotificationInViewController:self.notificationViewController
                                                  title:@"An error occurred"
                                               subtitle:[[self parseTorrentFailure:responseData] sentenceParsedString]
                                                  image:nil
                                                   type:TSMessageNotificationTypeError
                                               duration:TSDURATION
                                               callback:^(void) {
                                               }
                                            buttonTitle:nil
                                         buttonCallback:nil
                                             atPosition:TSMessageNotificationPositionTop
                                   canBeDismissedByUser:YES];
        } else {
            [TSMessage showNotificationWithTitle:@"An error occurred"
                                        subtitle:[[self parseTorrentFailure:responseData] sentenceParsedString]
                                            type:TSMessageNotificationTypeError];
        }
    } else {
        if (self.notificationViewController) {
            [TSMessage showNotificationInViewController:self.notificationViewController
                                                  title:@"An error occurred"
                                               subtitle:@"No error info provided, are you sure that's the right port?"
                                                  image:nil
                                                   type:TSMessageNotificationTypeError
                                               duration:TSDURATION
                                               callback:nil
                                            buttonTitle:nil
                                         buttonCallback:nil
                                             atPosition:TSMessageNotificationPositionTop
                                   canBeDismissedByUser:YES];
        } else {
            [TSMessage showNotificationWithTitle:@"An error occurred"
                                        subtitle:@"No error info provided, are you sure that's the right port?"
                                            type:TSMessageNotificationTypeError];
        }
    }
    responseData = [NSMutableData new];
    hashString = nil;
    torrentName = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [challenge.sender useCredential:[NSURLCredential credentialWithUser:@"user" password:@"password" persistence:NSURLCredentialPersistencePermanent]
         forAuthenticationChallenge:challenge];
}

@end
