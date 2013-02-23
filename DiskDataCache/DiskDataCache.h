//
//  DiskDataCache.h
//  Tuli
//
//  Created by Charlie Wu on 29/01/13.
//  Copyright (c) 2013 Charlie Wu. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DefaultCacheCount 200
#define DefaultCacheFolder @"diskCache"

@interface DiskDataCache : NSObject

+ (id) globalInstant;

- (void)setMaxCacheCount:(long)maxCacheCount;

- (NSData *)dataForKey:(NSString *)key;

- (void)setData:(NSData *)data forKey:(NSString *)key;

@end
