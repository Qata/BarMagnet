//
//  SeedStuffSeedbox.m
//  BarMagnet
//
//  Created by Charlotte Tortorella on 2/03/2014.
//  Copyright (c) 2014 Charlotte Tortorella. All rights reserved.
//

#import "SeedStuffSeedbox.h"
#import "FileHandler.h"

@implementation SeedStuffSeedbox

+ (NSString *)name {
  return @"SeedStuff Seedbox";
}

+ (NSString *)defaultPort {
  return @"443";
}

- (NSString *)getAppendedURL {
  return [NSString stringWithFormat:@"%@/user/%@", self.getBaseURL, [[self getWebDataForKey:@"username"] orSome:@""]];
}

+ (BOOL)supportsRelativePath {
  return NO;
}

- (NSString *)getBaseURL {
  NSString *urlString = nil;
  NSString *port = [self.class defaultPort];
  NSString *username = [[[self getWebDataForKey:@"username"] orSome:@""] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  NSString *password = [[[self getWebDataForKey:@"password"] orSome:@""] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  NSString *url = [[self getWebDataForKey:@"url"] orSome:@"localhost"];

  url = [url stringByReplacingOccurrencesOfString:@"http://" withString:@""];
  url = [url stringByReplacingOccurrencesOfString:@"https://" withString:@""];

  // Make sure both the username and the password are non-nil values, otherwise the ":" will prevent the URL from loading
  if ([username length] && [password length]) {
    urlString = [NSString stringWithFormat:@"https://%@:%@@%@:%@", username, password, url, port];
  } else if ([username length] > 0) {
    urlString = [NSString stringWithFormat:@"https://%@@%@:%@", username, url, port];
  } else {
    urlString = [NSString stringWithFormat:@"https://%@:%@", url, port];
  }

  return urlString;
}

- (NSString *)getUserFriendlyAppendedURL {
  return [self.getBaseURL stringByAppendingPathComponent:@"rutorrent"];
}

@end
