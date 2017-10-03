//
//  FileHandler.m
//  Bar Magnet
//
//  Created by Charlotte Tortorella on 24/03/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#import "FileHandler.h"
#import "TorrentClient.h"
#import "TorrentDelegate.h"

@implementation FileHandler

static FileHandler *sharedInstance;

+ (void)initialize {
    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        sharedInstance = [FileHandler new];
    }
}

+ (FileHandler *)sharedInstance {
    return sharedInstance;
}

- (id)init {
    if (self = [super init]) {
        masterDict = [[[NSUserDefaults standardUserDefaults] objectForKey:@"delegates"] mutableCopy]
                         ? [[[NSUserDefaults standardUserDefaults] objectForKey:@"delegates"] mutableCopy]
                         : [NSMutableDictionary new];

        for (NSString *key in masterDict.allKeys) {
            masterDict[key] = [masterDict[key] mutableCopy];
        }

        if (![[NSSet setWithArray:masterDict.allKeys] containsObject:@"settings"]) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            dict[@"server_name"] = @"Default";
            dict[@"server_type"] = @"Transmission";
            dict[@"refresh_connection_seconds"] = @2;
            dict[@"notification_format"] = @"%t added to %s";
            dict[@"query_format"] = @"google.com/search?q=%query%";
            dict[@"sort_by"] = @"Progress";

            [masterDict setObject:dict forKey:@"settings"];
        }
    }

    return self;
}

- (id)settingsValueForKey:(NSString *)key {
    return [[NSSet setWithArray:masterDict.allKeys] containsObject:@"settings"] ? masterDict[@"settings"][key] : @"";
}

- (void)setSettingsValue:(id)value forKey:(NSString *)key {
    if (value) {
        if (!masterDict[@"settings"]) {
            masterDict[@"settings"] = NSMutableDictionary.new;
        }
        masterDict[@"settings"][key] = value;
    }
}

- (NSOption *)webDataValueForKey:(NSString *)key {
    NSString *name = [self settingsValueForKey:@"server_name"];
    for (NSDictionary *dict in [NSUserDefaults.standardUserDefaults objectForKey:@"clients"]) {
        if ([dict[@"name"] isEqualToString:name]) {
            if ([dict[key] isKindOfClass:NSString.class]) {
                if ([dict[key] length]) {
                    return [NSOption fromNil:dict[key]];
                }
            } else {
                return [NSOption fromNil:dict[key]];
            }
        }
    }
    return NSOption.none;
}

- (NSOption *)oldWebDataValueForKey:(NSString *)key {
    const NSString *dn = [FileHandler.sharedInstance settingsValueForKey:@"server_type"];

    if ([[NSSet setWithArray:masterDict.allKeys] containsObject:dn]) {
        if ([masterDict[dn][key] isKindOfClass:NSString.class]) {
            return [masterDict[dn][key] length] ? [NSOption fromNil:masterDict[dn][key]] : [NSOption none];
        } else {
            return [NSOption fromNil:masterDict[dn][key]];
        }
    } else {
        return [NSOption none];
    }
}

- (void)setWebDataValue:(id)value forKey:(NSString *)key andDict:(NSString *)dictName {
    const NSString *dn = [dictName length] ? dictName : [FileHandler.sharedInstance settingsValueForKey:@"server_type"];

    if (value && [masterDict.allKeys containsObject:dn]) {
        masterDict[dn][key] = value;
    }
}

- (void)saveAllPlists {
    [[NSUserDefaults standardUserDefaults] setObject:masterDict forKey:@"delegates"];
}

@end
