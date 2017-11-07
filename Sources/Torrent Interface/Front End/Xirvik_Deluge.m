//
//  Xirvik_Deluge.m
//  BarMagnet
//
//  Created by Charlotte Tortorella on 2017-11-04.
//  Copyright © 2017 Charlotte Tortorella. All rights reserved.
//

#import "Xirvik_Deluge.h"

@implementation Xirvik_Deluge

+ (NSString *)name {
    return @"Xirvik Deluge";
}

+ (NSString *)defaultPort {
    return @"443";
}

+ (BOOL)supportsRelativePath {
    return NO;
}

- (NSString *)getUserFriendlyAppendString {
    return @"/deluge";
}

- (NSString *)getURLAppendString {
    return @"/deluge/json";
}

+ (BOOL)isSeedbox {
    return YES;
}

+ (BOOL)hasQR {
    return YES;
}

+ (BOOL)showsUsername {
    return NO;
}

- (NSMutableURLRequest *)universalPOSTSetting {
    NSMutableURLRequest *retVal;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.getAppendedURLWithoutAuth] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
    randomID = @(arc4random());
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setValue:@"Basic Og==" forHTTPHeaderField:@"Authorization"];
    [request setValue:[[self getWebDataForKey:@"password"] orSome:@""] forHTTPHeaderField:@"X-QR-Auth"];
    retVal = [request copy];
    
    NSError *error = nil;
    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:@{
                                                                   @"id" : randomID,
                                                                   @"method" : @"auth.login",
                                                                   @"params" : @[ @"deluge" ]
                                                                   }
                                                         options:0
                                                           error:&error]];
    if (error) {
        errorString = error.localizedDescription;
    }
    
    NSData *returnedData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
    
    NSDictionary *dict = [returnedData length] ? [NSJSONSerialization JSONObjectWithData:returnedData options:0 error:nil] : nil;
    if ([dict respondsToSelector:@selector(objectForKey:)]) {
        if ([dict[@"result"] isEqual:@NO]) {
            errorString = @"Incorrect password";
        }
    }
    return retVal;
}

- (BOOL)isValidJobsData:(NSData *)data {
    return NO;
}

- (NSMutableURLRequest *)checkTorrentJobs {
    NSMutableURLRequest *request = [self universalPOSTSetting];
    NSDictionary *JSONObject = @{
                                 @"id" : @([randomID intValue] + 3),
                                 @"method" : @"core.get_torrents_status",
                                 @"params" : @[
                                         @{},
                                         @[
                                             @"hash", @"name", @"progress", @"state", @"download_payload_rate", @"upload_payload_rate", @"eta", @"total_done", @"total_uploaded", @"total_size",
                                             @"num_peers", @"num_seeds", @"ratio"
                                             ]
                                         ]
                                 };
    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:JSONObject options:0 error:nil]];
    
    return request;
}

- (NSString *)getHyperTextString {
    return @"https://";
}

- (NSString *)getBaseURL {
    return [self.getHyperTextString stringByAppendingString:[[self getWebDataForKey:@"url"] orSome:@""]];
}

@end
