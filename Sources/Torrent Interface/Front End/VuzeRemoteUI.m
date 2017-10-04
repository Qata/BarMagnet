//
//  Transmission.m
//  Bar Magnet
//
//  Created by Charlotte Tortorella on 16/03/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#import "VuzeRemoteUI.h"
#import "ConnectionHandler.h"
#import "FileHandler.h"

@implementation VuzeRemoteUI

+ (NSString *)name {
    return @"Vuze Remote UI";
}

+ (NSNumber *)completeNumber {
    return @1;
}

- (BOOL)isValidJobsData:(NSData *)data {
    id JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

    if ([JSON respondsToSelector:@selector(objectForKey:)]) {
        if ([JSON[@"arguments"] respondsToSelector:@selector(objectForKey:)]) {
            if ([[JSON[@"arguments"] allKeys] containsObject:@"torrents"]) {
                return YES;
            }
        }
    }
    return NO;
}

- (NSMutableURLRequest *)requestWithJSON:(NSDictionary *)JSON {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.getAppendedURL]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:JSON options:0 error:nil]];

    return request;
}

- (NSMutableURLRequest *)HTTPRequestWithMethod:(NSString *)method andHashes:(NSArray *)hashes {
    return [self requestWithJSON:@{ @"method" : method,
                                    @"arguments" : @{@"ids" : hashes} }];
}
- (NSMutableURLRequest *)checkTorrentJobs {
    return [self requestWithJSON:@{
        @"method" : @"torrent-get",
        @"arguments" : @{
            @"fields" : @[
                @"hashString", @"name", @"percentDone", @"status", @"sizeWhenDone", @"downloadedEver", @"uploadedEver", @"peersGettingFromUs", @"peersSendingToUs",
                @"rateDownload", @"rateUpload", @"eta", @"uploadRatio", @"addedDate", @"doneDate"
            ]
        }
    }];
}

- (NSDictionary *)getTorrentJobs {
    id JSON = [NSJSONSerialization JSONObjectWithData:self.jobsData options:0 error:nil];

    if ([JSON respondsToSelector:@selector(objectForKey:)]) {
        if ([JSON[@"arguments"] respondsToSelector:@selector(objectForKey:)]) {
            if ([[JSON[@"arguments"] allKeys] containsObject:@"torrents"]) {
                return JSON[@"arguments"][@"torrents"];
            }
        }
    }
    return nil;
}

- (NSDictionary *)virtualHandleTorrentJobs {
    NSMutableDictionary *tempJobs = [NSMutableDictionary new];

    for (NSDictionary *dict in [self getTorrentJobs]) {
        NSString *status = @"Error";
        switch ([dict[@"status"] intValue]) {
        case 0:
            status = @"Paused";
            break;
        case 1:
        case 3:
        case 5:
            status = @"Queued";
            break;
        case 2:
            status = @"Checking";
            break;
        case 4:
            status = @"Downloading";
            break;
        case 6:
            status = @"Seeding";
            break;
        }
        NSNumber *percentDone = @0;
        if ([[NSSet setWithArray:dict.allKeys] containsObject:@"percentDone"]) {
            percentDone = dict[@"percentDone"];
        } else {
            if ([dict[@"downloadedEver"] doubleValue] && [dict[@"sizeWhenDone"] doubleValue]) {
                percentDone = @([dict[@"downloadedEver"] doubleValue] / [dict[@"sizeWhenDone"] doubleValue]);
            }
        }

        NSString *ETA = [dict[@"eta"] respondsToSelector:@selector(intValue)] ? [dict[@"eta"] ETAString] : @"∞";
        if (dict[@"addedDate"] && dict[@"doneDate"]) {
            [self insertTorrentJobsDictWithArray:@[
                dict[@"hashString"], dict[@"name"], percentDone, status, [dict[@"rateDownload"] transferRateString], [dict[@"rateUpload"] transferRateString], ETA,
                [dict[@"downloadedEver"] sizeString], [dict[@"uploadedEver"] sizeString], dict[@"sizeWhenDone"], dict[@"peersGettingFromUs"], dict[@"peersSendingToUs"],
                dict[@"rateDownload"], dict[@"rateUpload"], dict[@"uploadRatio"], dict[@"addedDate"], dict[@"doneDate"]
            ]
                                        intoDict:tempJobs];
        } else {
            [self insertTorrentJobsDictWithArray:@[
                dict[@"hashString"], dict[@"name"], percentDone, status, [dict[@"rateDownload"] transferRateString], [dict[@"rateUpload"] transferRateString], ETA,
                [dict[@"downloadedEver"] sizeString], [dict[@"uploadedEver"] sizeString], dict[@"sizeWhenDone"], dict[@"peersGettingFromUs"], dict[@"peersSendingToUs"],
                dict[@"rateDownload"], dict[@"rateUpload"], dict[@"uploadRatio"]
            ]
                                        intoDict:tempJobs];
        }
    }
    return tempJobs;
}

- (NSString *)getUserFriendlyAppendString {
    return @"";
}

- (NSString *)getURLAppendString {
    return @"/transmission/rpc";
}

- (BOOL)receivedSuccessConditional:(NSData *)response {
    return [[NSJSONSerialization JSONObjectWithData:response options:0 error:nil][@"result"] isEqualToString:@"success"] ||
           [[response toUTF8String] rangeOfString:@"<h1>200: OK</h1>"].location != NSNotFound;
}

- (NSURLRequest *)virtualHandleMagnetLink:(NSString *)magnetLink {
    NSMutableDictionary *arguments = [NSMutableDictionary dictionaryWithDictionary:@{@"filename" : magnetLink}];
    NSString *directory = [[FileHandler.sharedInstance webDataValueForKey:@"directory"] orSome:@""];

    if (directory.length) {
        [arguments setObject:directory forKey:@"download-dir"];
    }

    return [self requestWithJSON:@{@"method" : @"torrent-add", @"arguments" : arguments}];
}

- (NSURLRequest *)virtualHandleTorrentFile:(NSData *)fileData withURL:(NSURL *)fileURL {
    NSMutableDictionary *arguments = [NSMutableDictionary dictionaryWithDictionary:@{@"metainfo" : [fileData base64EncodedStringWithOptions:0]}];
    NSString *directory = [[FileHandler.sharedInstance webDataValueForKey:@"directory"] orSome:@""];

    if (directory.length) {
        [arguments setObject:directory forKey:@"download-dir"];
    }

    return [self requestWithJSON:@{@"method" : @"torrent-add", @"arguments" : arguments}];
}

- (NSURLRequest *)virtualPauseTorrent:(NSString *)hash {
    return [self HTTPRequestWithMethod:@"torrent-stop" andHashes:@[ hash ]];
}

- (NSURLRequest *)virtualResumeTorrent:(NSString *)hash {
    return [self HTTPRequestWithMethod:@"torrent-start" andHashes:@[ hash ]];
}

- (NSURLRequest *)virtualPauseAllTorrents {
    return [self HTTPRequestWithMethod:@"torrent-stop" andHashes:self.getJobsDict.allKeys];
}

- (NSURLRequest *)virtualResumeAllTorrents {
    return [self HTTPRequestWithMethod:@"torrent-start" andHashes:self.getJobsDict.allKeys];
}

- (NSURLRequest *)virtualRemoveTorrent:(NSString *)hash removeData:(BOOL)removeData {
    return [self requestWithJSON:@{ @"method" : @"torrent-remove",
                                    @"arguments" : @{@"ids" : @[ hash ], @"delete-local-data" : @(removeData)} }];
}

- (NSString *)parseTorrentFailure:(NSData *)response {
    NSError *error = nil;
    NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:response options:0 error:&error];
    if (!JSON || error) {
        return @"Client threw an error";
    } else if ([[JSON allKeys] containsObject:@"result"]) {
        return JSON[@"result"];
    }
    return @"Unknown error encountered";
}

+ (NSString *)defaultPort {
    return @"9091";
}

+ (BOOL)supportsDirectoryChoice {
    return YES;
}

- (BOOL)supportsAddedDate {
    return YES;
}

- (BOOL)supportsCompletedDate {
    return YES;
}

@end
