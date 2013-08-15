//
//  NSOption.h
//  BarMagnet
//
//  Created by Carlo Tortorella on 14/08/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSOption : NSObject

+ (NSOption *)fromNil:(id)object;
+ (NSOption *)some:(id)object;
+ (NSOption *)none;
- (BOOL)isSome;
- (BOOL)isNone;
- (id)orSome:(id)other;

@property (nonatomic, strong, readonly) id some;

@end