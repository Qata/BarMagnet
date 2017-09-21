//
//  NSArray+Functions.m
//  BarMagnet
//
//  Created by Charlotte Tortorella on 7/07/13.
//  Copyright (c) 2013 Charlotte Tortorella. All rights reserved.
//

#import "NSArray+Functions.h"

@implementation NSArray (Functions)

- (NSArray *)intersperse:(id)object {
  if ([self count] > 1) {
    NSMutableArray *retVal = [NSMutableArray arrayWithArray:self];
    int iter = 0;
    for (int i = 1; i < [self count]; i++) {
      [retVal insertObject:object atIndex:i + iter];
      ++iter;
    }
    return retVal;
  }

  return self;
}

- (NSArray *)reverse {
  NSMutableArray *retVal = [NSMutableArray new];
  for (id obj in self) {
    [retVal insertObject:obj atIndex:retVal.count];
  }
  return retVal;
}

@end
