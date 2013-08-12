//
//  TorrentDictFunctions.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 11/07/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "TorrentDictFunctions.h"
#import "TorrentDelegate.h"

@implementation TorrentDictFunctions

+ (NSString *)jobStatusFromCurrentJob:(NSDictionary *)currentJob
{
	return [currentJob objectForKey:@"status"];
}

@end
