//
//  NSNumber+TransferRateFormatting.m
//  Bar Magnet
//
//  Created by Charlotte Tortorella on 1/07/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//


@implementation NSNumber (TransferRateFormatting)

- (BOOL)isZero
{
	return self.doubleValue == 0;
}

- (NSString *)transferRateString
{
	return [self.sizeString stringByAppendingString:@"/s"];
}

- (NSString *)sizeString
{
	if (self.longLongValue)
	{
		switch ((unsigned)log2(self.doubleValue) / 10)
		{
			case 1:
				return [NSString stringWithFormat:@"%.1f KiB", self.doubleValue / (1ULL << 10)];
			case 2:
				return [NSString stringWithFormat:@"%.1f MiB", self.doubleValue / (1ULL << 20)];
			case 3:
				return [NSString stringWithFormat:@"%.1f GiB", self.doubleValue / (1ULL << 30)];
			case 4:
				return [NSString stringWithFormat:@"%.1f TiB", self.doubleValue / (1ULL << 40)];
			case 5:
				return [NSString stringWithFormat:@"%.1f PiB", self.doubleValue / (1ULL << 50)];
			case 6:
				return [NSString stringWithFormat:@"%.1f EiB", self.doubleValue / (1ULL << 60)];
		}
	}
	return [NSString stringWithFormat:@"%lld B", self.longLongValue];
}

@end
