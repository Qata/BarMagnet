//
//  NSOption.m
//  BarMagnet
//
//  Created by Charlotte Tortorella on 14/08/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#import "NSOption.h"

@implementation NSOption

@synthesize some = _some;

+ (NSOption *)fromNil:(id)object
{
	return object ? [NSOption some:object] : [NSOption none];
}

+ (NSOption *)some:(id)object
{
	return [[NSOption alloc] initWithSome:object];
}

- (NSOption *)initWithSome:(id)some
{
	if (self = [super init])
	{
		_some = some;
	}
	return self;
}

- (id)orSome:(id)other
{
	return [self some] ? [self some] : other;
}

+ (NSOption *)none
{
	return [NSOption some:nil];
}

- (BOOL)isSome
{
	return [self some] != nil;
}

- (BOOL)isNone
{
	return [self some] == nil;
}

- (BOOL)isEqual:(id)object
{
    return object == nil || ![[object class] isEqual:self.class] ? NO : [self.some isEqual:((NSOption *)object).some];
}

- (NSUInteger)hash
{
    return [[self some] hash];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ some: %@>", NSStringFromClass([self class]), self.some];
}

@end
