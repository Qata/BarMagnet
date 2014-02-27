//
//  StringHandling.m
//  Bar Magnet
//
//  Created by Carlo Tortorella on 15/03/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "NSOption.h"
#import "FileHandler.h"
#import "StringHandler.h"
@implementation StringHandler

+ (NSString *) getStringBetween:(NSString *)key andString:(NSString *)terminator fromString:(NSString *)baseString
{
	NSString * retVal = @"";
	terminator = terminator ? terminator : @"";
	
	long loc1 = [baseString rangeOfString:key].location;
	long loc2 = 0;
	
	if (loc1 != NSNotFound)
	{
		loc2 = [[baseString substringWithRange:NSMakeRange(loc1 + [key length], [baseString length] - (loc1 + [key length]))] rangeOfString:terminator].location + loc1 + [key length];
	}
	
	if (loc1 != NSNotFound && loc2 != NSNotFound && loc2 > loc1)
	{
		NSRange range1 = [baseString rangeOfString:key];
		range1.location += range1.length;
		range1.length = baseString.length - range1.location;
		NSString * rangeStr = [baseString substringWithRange:range1];
		NSRange range2 = [rangeStr rangeOfString:terminator];
		retVal = [baseString substringWithRange:NSMakeRange(range1.location, range2.location)];
	}
	else if (loc1 != NSNotFound)
	{
		NSRange range1 = [baseString rangeOfString:key];
		range1.location += range1.length;
		range1.length = baseString.length - range1.location;
		retVal = [baseString substringWithRange:range1];
	}
	
	return retVal;
}

+ (NSString *)parseURLAsHumanReadable:(NSString*)URL
{
	NSString * replacementStr = URL;
	
	replacementStr = [replacementStr stringByReplacingOccurrencesOfString:@"+" withString:@" "];
	replacementStr = [replacementStr stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
	
	return replacementStr;
}

+ (NSString *)parseNotification:(NSString *)notificationText;
{
	NSString * notification = [FileHandler.sharedInstance settingsValueForKey:@"notification_format"];
	NSString * url = [[FileHandler.sharedInstance webDataValueForKey:@"url" andDict:nil] orSome:@""];
	NSString * port = [[FileHandler.sharedInstance webDataValueForKey:@"port" andDict:nil] orSome:@""];
	NSString * user = [[FileHandler.sharedInstance webDataValueForKey:@"username" andDict:nil] orSome:@""];
	NSString * serverType = [FileHandler.sharedInstance settingsValueForKey:@"server_type"];
	
	notification = [notification length] ? notification : @"%t";
	
	notification = [notification stringByReplacingOccurrencesOfString:@"%t" withString:notificationText];
	notification = [notification stringByReplacingOccurrencesOfString:@"%u" withString:user];
	notification = [notification stringByReplacingOccurrencesOfString:@"%s" withString:[NSString stringWithFormat:@"%@:%@", url, port]];
	notification = [notification stringByReplacingOccurrencesOfString:@"%c" withString:serverType];
	
	return notification;
}

@end

@implementation NSString (StringHandler)

- (NSString *)transferRateString
{
	return [[self sizeString] stringByAppendingString:@"/s"];
}

- (NSString *)sizeString
{
	return [[self toNumber] sizeString];
}

- (NSString *)encodeAmpersands
{
	return [self stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
}

- (NSString *)sentenceParsedString
{
	return [self length] ? [self stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[self substringToIndex:1] uppercaseString]] : self;
}

- (NSString *) getStringBetween:(NSString *)key andString:(NSString *)terminator
{
	return [StringHandler getStringBetween:key andString:terminator fromString:self];
}

- (NSNumber *)toNumber
{
	NSNumberFormatter * f = [NSNumberFormatter new];
	[f setNumberStyle:NSNumberFormatterDecimalStyle];
	NSNumber * retVal = [f numberFromString:self];
	return retVal;
}


- (NSString *)stringWithPrecedingAndSucceedingSlashes
{
	NSMutableString * str = [NSMutableString stringWithString:self];
	if ([self length])
	{
		if ([str characterAtIndex:0] != '/')
		{
			[str insertString:@"/" atIndex:0];
		}
		if ([str characterAtIndex:[str length] - 1] != '/')
		{
			[str appendString:@"/"];
		}
		return str;
	}
	return @"/";
}

+ (NSString *) getStringBetween:(NSString *)key andString:(NSString *)terminator fromString:(NSString *)baseString
{
	return [StringHandler getStringBetween:key andString:terminator fromString:baseString];
}

+ (NSString *)stringWithASCIIString:(const char *)str
{
	return [[NSString alloc] initWithData:[NSData dataWithBytes:str length:strlen(str)] encoding:NSASCIIStringEncoding];
}

@end

@implementation NSData (StringHandler)

- (NSString *)toUTF8String
{
	return [[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding];
}

- (NSString *)toASCIIString
{
	return [[NSString alloc] initWithData:self encoding:NSASCIIStringEncoding];
}

@end

@implementation NSNumber (SignificantDates)

- (NSString *)ETAString
{
	NSMutableArray * retVal = [NSMutableArray new];
	if ([self integerValue] == -1 || [self unsignedIntegerValue] == 1827387392)
	{
		return @"∞";
	}
	else if (![self isZero])
	{
		NSNumber * seconds = @([self unsignedIntegerValue] % 60);
		NSUInteger minutes = [self unsignedIntegerValue] / 60;
		NSUInteger hours = minutes / 60;
		NSUInteger days = hours / 24;
		NSUInteger weeks = days / 7;
		NSUInteger months = weeks / 52;
		NSUInteger years = months / 12;

		NSArray * numbers = @[@(years), @(weeks % 52), @(days % 7), @(hours % 24), @(minutes % 60), seconds];

		int counter = 0;
		for (NSNumber * number in numbers)
		{
			if ([number unsignedIntegerValue])
			{
				[retVal addObject:[NSString stringWithFormat:@"%@%@", number, @[@"y", @"w", @"d", @"h", @"m", @"s"][counter]]];
				if ([retVal count] > 1)
				{
					return [retVal componentsJoinedByString:@" "];
				}
			}
			++counter;
		}
	}
	return [retVal count] ? retVal[0] : @"";
}

@end