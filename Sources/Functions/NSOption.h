//
//  NSOption.h
//  BarMagnet
//
//  Created by Charlotte Tortorella on 14/08/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSOption : NSObject

+ (NSOption *)fromNil:(id)object;
+ (NSOption *)some:(id)object;
+ (NSOption *)none;
- (BOOL)isSome;
- (BOOL)isNone;
- (id)orSome:(id)other;

@property(nonatomic, strong, readonly) id some;

@end
