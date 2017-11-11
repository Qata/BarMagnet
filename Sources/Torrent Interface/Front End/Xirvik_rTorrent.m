//
//  Xirvik_rTorrent.m
//  BarMagnet
//
//  Created by Charlotte Tortorella on 26/09/2015.
//  Copyright © 2015 Charlotte Tortorella. All rights reserved.
//

#import "Xirvik_rTorrent.h"
#import "NSData+BEncode.h"

@implementation Xirvik_rTorrent

+ (NSString *)name {
    return @"Xirvik rTorrent";
}

+ (NSString *)defaultPort {
    return @"443";
}

+ (BOOL)supportsRelativePath {
    return NO;
}

- (NSMutableURLRequest *)RPCRequestWithMethodName:(NSString *)methodName {
    NSMutableURLRequest *request = [super RPCRequestWithMethodName:methodName];
    [NSMutableURLRequest requestWithURL:[[NSURL URLWithString:self.getAppendedURL] URLByAppendingPathComponent:@"plugins/httprpc/action.php"]];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setValue:@"Basic Og==" forHTTPHeaderField:@"Authorization"];
    [request setValue:[[self getWebDataForKey:@"password"] orSome:@""] forHTTPHeaderField:@"X-QR-Auth"];
    return request;
}

- (NSMutableURLRequest *)universalPOSTSetting {
    NSMutableURLRequest *request = [super universalPOSTSetting];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setValue:@"Basic Og==" forHTTPHeaderField:@"Authorization"];
    [request setValue:[[self getWebDataForKey:@"password"] orSome:@""] forHTTPHeaderField:@"X-QR-Auth"];
    return request;
}

- (NSString *)getURLAppendString {
    return @"rtorrent";
}

- (NSString *)getUserFriendlyAppendString {
    return @"rtorrent";
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

- (NSString *)getHyperTextString {
    return @"https://";
}

- (NSString *)getBaseURL {
    return [self.getHyperTextString stringByAppendingString:[[self getWebDataForKey:@"url"] orSome:@""]];
}

@end
