//
//  FileHandler.h
//  Bar Magnet
//
//  Created by Charlotte Tortorella on 24/03/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileHandler : NSObject
{
	NSMutableDictionary * masterDict;
}
+ (FileHandler *)sharedInstance;

- (id)settingsValueForKey:(NSString *)key;
- (void)setSettingsValue:(id)value forKey:(NSString *)key;
- (NSOption *)webDataValueForKey:(NSString *)key;
- (NSOption *)oldWebDataValueForKey:(NSString *)key;
- (void)setWebDataValue:(id)value forKey:(NSString *)key andDict:(NSString *)dictName;
- (void)saveAllPlists;
@end
