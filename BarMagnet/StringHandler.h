//
//  StringHandling.h
//  Bar Magnet
//
//  Created by Carlo Tortorella on 15/03/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

@interface StringHandler : NSObject
+ (NSString *)getStringBetween:(NSString *)key andString:(NSString *)terminator fromString:(NSString *)baseString;
+ (NSString *)parseURLAsHumanReadable:(NSString *)url;
+ (NSString *)parseNotification:(NSString *)magnetLink;
@end

@interface NSString (StringHandler)
/**
 * Returns an NSString that consists of the return value from calling sizeString and then appending "/s". For more information, see sizeString.
 */
- (NSString *)transferRateString;
/**
 * Returns an approximation of the size of the integer value of the string in bytes by checking the size in bytes against 2^(10*x). 
 * If x > 0 then a greedy function is run that checks if x > (a multiple of 2^(10 * x)) until it finds the largest size.
 * The function then divides x by the aforementioned size and returns a string with a size identifier appended. E.g. if the size is > 1024 but < 1048576 then it would return "x KiB".
 */
- (NSString *)sizeString;
/**
 * Returns a string by replacing all ampersands with their percent encoded value.
 */
- (NSString *)encodeAmpersands;
/**
 * Returns an NSString with the character at index zero capitalised.
 */
- (NSString *)sentenceParsedString;
/**
 * Returns an NSString within two NSString keys.
 *
 * @param key The search parameter. If not found, an empty string is returned.
 * @param terminator The terminating parameter. If not found, but key is, a substring of [key .. end] is returned.
 */
- (NSString *)getStringBetween:(NSString *)key andString:(NSString *)terminator;
- (NSNumber *)toNumber;
/**
 * Checks if the string has slashes at index 0 and index (count - 1), if not, these are added to the string and returned.
 */
- (NSString *)stringWithPrecedingAndSucceedingSlashes;
/**
 * Returns an NSString within two NSString keys.
 *
 * @param key The search parameter. If not found, an empty string is returned.
 * @param terminator The terminating parameter. If not found, but key is, a substring of [key .. end] is returned.
 * @param baseString The string to search for the key and terminator in.
 */
+ (NSString *)getStringBetween:(NSString *)key andString:(NSString *)terminator fromString:(NSString *)baseString;
+ (NSString *)stringWithASCIIString:(const char *)str;
@end

@interface NSData (StringHandler)
/**
 * Converts NSData to an NSString using NSUTF8StringEncoding
 */
- (NSString *)toUTF8String;
/**
 * Converts NSData to an NSString using NSASCIIStringEncoding
 */
- (NSString *)toASCIIString;
@end

@interface NSNumber (SignificantDates)

- (NSString *)ETAString;

@end