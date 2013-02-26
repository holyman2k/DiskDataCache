//
//  DiskDataCache.h
//  Tuli
//
//  Created by Charlie Wu on 29/01/13.
//  Copyright (c) 2013 Charlie Wu. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DefaultCacheSize 200 * 1024 * 1024 // 200mb cache
//#define DefaultCacheSize 2 * 1024 * 1024
#define DefaultCacheFolder @"DiskCache"

@interface DiskDataCache : NSObject

+ (id) globalInstant;

- (void)setMaxCacheSize:(long)maxCacheSize;

- (NSData *)dataForKey:(NSString *)key;

- (void)setData:(NSData *)data forKey:(NSString *)key;

- (void)clearCache;

- (long)currentCacheSize;

- (int)currentCachedObjectCount;

- (BOOL)validateCache;

@end
