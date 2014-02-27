//
//  NSNumber+TransferRateFormatting.h
//  Bar Magnet
//
//  Created by Carlo Tortorella on 1/07/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

@interface NSNumber (TransferRateFormatting)

- (NSString *)transferRateString;
- (NSString *)sizeString;
- (BOOL)isZero;

@end
