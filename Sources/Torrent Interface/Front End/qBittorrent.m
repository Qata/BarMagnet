//
//  qBittorrent.m
//  Bar Magnet
//
//  Created by Charlotte Tortorella on 13/06/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#import "qBittorrent.h"
#import "FileHandler.h"

#import "ConnectionHandler.h"

@implementation qBittorrent

+ (NSString *)name {
    return @"qBittorrent";
}

+ (NSNumber *)completeNumber {
    return @1;
}

- (BOOL)isValidJobsData:(NSData *)data {
    id JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if ([JSON respondsToSelector:@selector(objectAtIndex:)]) {
        return YES;
    }
    return NO;
}

- (NSMutableURLRequest *)checkTorrentJobs {
    return [NSMutableURLRequest requestWithURL:[[NSURL URLWithString:self.getBaseURL] URLByAppendingPathComponent:@"json/torrents"]];
}

- (id)getTorrentJobs {
    id JSON = [NSJSONSerialization JSONObjectWithData:self.jobsData options:0 error:nil];
    if ([JSON respondsToSelector:@selector(objectAtIndex:)]) {
        return JSON;
    }
    return nil;
}

- (NSDictionary *)virtualHandleTorrentJobs {
    NSMutableDictionary *tempJobs = [NSMutableDictionary new];
    NSArray *torrentJobs = [self getTorrentJobs];

    for (NSDictionary *dict in torrentJobs) {
        NSString *state = @"Unknown State";

        if ([dict[@"state"] isKindOfClass:NSString.class] && [dict[@"state"] length] > 2) {
            NSString *postFix = [dict[@"state"] substringFromIndex:[dict[@"state"] length] - 2];
            if ([postFix isEqualToString:@"UP"] || [postFix isEqualToString:@"DL"]) {
                state = [[dict[@"state"] substringToIndex:[dict[@"state"] length] - 2] sentenceParsedString];
            } else {
                state = [dict[@"state"] sentenceParsedString];
            }

            if ([dict[@"state"] isEqualToString:@"stalledUP"]) {
                state = @"Seeding";
            }
        } else if ([dict[@"state"] isKindOfClass:NSNumber.class]) {
            switch ([dict[@"state"] intValue]) {
            case 1:
                state = @"Error";
                break;
            case 2:
            case 3:
                state = @"Paused";
                break;
            case 4:
            case 5:
                state = @"Queued";
                break;
            case 6:
                state = @"Seeding";
                break;
            case 7:
            case 11:
                state = @"Stalled";
                break;
            case 8:
            case 9:
                state = @"Checking";
                break;
            case 10:
                state = @"Downloading";
                break;
            }
        }

        if ([dict respondsToSelector:@selector(objectForKey:)]) {
            [self insertTorrentJobsDictWithArray:@[ dict[@"hash"], dict[@"name"], dict[@"progress"], state, dict[@"dlspeed"], dict[@"upspeed"], dict[@"eta"] ]
                                        intoDict:tempJobs];
        }
    }
    return tempJobs;
}

- (NSString *)getUserFriendlyAppendString {
    return [[FileHandler.sharedInstance webDataValueForKey:@"relative_path"] orSome:@""];
}

- (NSString *)getURLAppendString {
    return [[[FileHandler.sharedInstance webDataValueForKey:@"relative_path"] orSome:@""] stringByAppendingPathComponent:@"command"];
}

- (BOOL)receivedSuccessConditional:(NSData *)response {
    return YES;
}

- (NSString *)parseTorrentFailure:(NSData *)response {
    return @"An unknown error occurred";
}

- (NSMutableURLRequest *)universalPOSTSetting {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.getAppendedURL]];
    [request setHTTPMethod:@"POST"];

    return request;
}

- (NSURLRequest *)virtualHandleMagnetLink:(NSString *)magnetLink {
    NSMutableURLRequest *request = [self universalPOSTSetting];
    [request setURL:[[request URL] URLByAppendingPathComponent:@"download"]];
    [request setHTTPBody:[[NSString stringWithFormat:@"urls=%@", magnetLink.encodeAmpersands] dataUsingEncoding:NSUTF8StringEncoding]];
    return request;
}

- (NSURLRequest *)virtualHandleTorrentFile:(NSData *)fileData withURL:(NSURL *)fileURL {
    return [ConnectionHandler createMultipartFormRequestWithHost:[[[self universalPOSTSetting] URL] URLByAppendingPathComponent:@"upload"]
                                                 dispositionName:@"torrentfile"
                                                         fileURL:fileURL
                                                         andData:fileData];
}

- (NSURLRequest *)virtualPauseTorrent:(NSString *)hash {
    NSMutableURLRequest *request = [self universalPOSTSetting];
    [request setURL:[[request URL] URLByAppendingPathComponent:@"pause"]];
    [request setHTTPBody:[[NSString stringWithFormat:@"hash=%@", hash.encodeAmpersands] dataUsingEncoding:NSUTF8StringEncoding]];
    return request;
}

- (NSURLRequest *)virtualResumeTorrent:(NSString *)hash {
    NSMutableURLRequest *request = [self universalPOSTSetting];
    [request setURL:[[request URL] URLByAppendingPathComponent:@"resume"]];
    [request setHTTPBody:[[NSString stringWithFormat:@"hash=%@", hash.encodeAmpersands] dataUsingEncoding:NSUTF8StringEncoding]];
    return request;
}

- (NSURLRequest *)virtualRemoveTorrent:(NSString *)hash removeData:(BOOL)removeData {
    NSMutableURLRequest *request = [self universalPOSTSetting];
    [request setURL:[[request URL] URLByAppendingPathComponent:removeData ? @"deletePerm" : @"delete"]];
    [request setHTTPBody:[[NSString stringWithFormat:@"hashes=%@", hash.encodeAmpersands] dataUsingEncoding:NSUTF8StringEncoding]];
    return request;
}

- (NSURLRequest *)virtualPauseAllTorrents {
    NSMutableURLRequest *request = [self universalPOSTSetting];
    [request setURL:[[request URL] URLByAppendingPathComponent:@"pauseall"]];
    return request;
}

- (NSURLRequest *)virtualResumeAllTorrents {
    NSMutableURLRequest *request = [self universalPOSTSetting];
    [request setURL:[[request URL] URLByAppendingPathComponent:@"resumeall"]];
    return request;
}

+ (NSString *)defaultPort {
    return @"8080";
}

@end
