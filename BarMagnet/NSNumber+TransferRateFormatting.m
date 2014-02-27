//
//  NSNumber+TransferRateFormatting.m
//  Bar Magnet
//
//  Created by Carlo Tortorella on 1/07/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//



@implementation NSNumber (TransferRateFormatting)

- (BOOL)isZero
{
	return [self intValue] == 0;
}

- (NSString *)transferRateString
{
	return [[self sizeString] stringByAppendingString:@"/s"];
}

- (NSString *)sizeString
{
	NSString * retVal = @"";

	if ([self longLongValue] >= 1LL << 40)
	{
		retVal = [NSString stringWithFormat:@"%.1f TiB", [self doubleValue] / (double)(1LL << 40)];
	}
	else if ([self longLongValue] >= 1 << 30)
	{
		retVal = [NSString stringWithFormat:@"%.1f GiB", [self doubleValue] / (double)(1 << 30)];
	}
	else if ([self longLongValue] >= 1 << 20)
	{
		retVal = [NSString stringWithFormat:@"%.1f MiB", [self doubleValue] / (double)(1 << 20)];
	}
	else if ([self longLongValue] >= 1 << 10)
	{
		retVal = [NSString stringWithFormat:@"%.1f KiB", [self doubleValue] / (double)(1 << 10)];
	}
	else
	{
		retVal = [NSString stringWithFormat:@"%lld B", self.longLongValue];
	}

	return retVal;
}

@end
