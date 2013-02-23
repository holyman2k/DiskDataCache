//
//  DiskDataCache.m
//  Tuli
//
//  Created by Charlie Wu on 29/01/13.
//  Copyright (c) 2013 Charlie Wu. All rights reserved.
//

#import "DiskDataCache.h"

#define CurrentCacheSizeStore @"CurrentCacheSize.txt"
#define CacheMapStore @"CacheMap.plist"
#define CacheKeysStore @"CacheKeys.plist"

@interface DiskDataCache()
@property (nonatomic) long maxCacheCount;
@property (nonatomic) long maxCacheSize;
@property (nonatomic) long currentCacheSize;
@property (strong, atomic) NSMutableDictionary *cachedMap;
@property (strong, atomic) NSMutableArray *cachedArray;
@property (strong, nonatomic) NSString *directory;
@end

@implementation DiskDataCache

static DiskDataCache *singleton = nil;

@synthesize maxCacheCount = _maxCacheCount;
@synthesize maxCacheSize = _maxCacheSize;
@synthesize currentCacheSize = _currentCacheSize;
@synthesize cachedMap = _cachedMap;
@synthesize cachedArray = _cachedArray;
@synthesize directory = _directory;

- (void)setCurrentCacheSize:(long)currentCacheSize
{
    NSLog(@"cache at %ld, max at %ld at %f%%", currentCacheSize, self.maxCacheSize, ((double)currentCacheSize/(double)self.maxCacheSize * 100));
    _currentCacheSize = currentCacheSize;
    NSString *size = [NSString stringWithFormat:@"%ld", currentCacheSize];
    [size writeToFile:[self filenameToPath:CurrentCacheSizeStore] atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (long)currentCacheSize
{
    if (!_currentCacheSize){
        NSString *value = [NSString stringWithContentsOfFile:[self filenameToPath:CurrentCacheSizeStore] encoding:NSUTF8StringEncoding error:nil];
        if (value) _currentCacheSize = [value longLongValue];
    }
    return _currentCacheSize;
}

+ (id) globalInstant
{
    @synchronized(self)
    {
        if (singleton == nil)
            singleton = [[self alloc] initWithDefaults];
    }
    
    return singleton;
}

- (id)initWithDefaults
{
    if (self = [super init])
    {
        self.maxCacheSize = DefaultCacheSize;
        self.directory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:DefaultCacheFolder];
        NSFileManager *fileManager = [[NSFileManager alloc]init];
        if (![fileManager fileExistsAtPath:self.directory isDirectory:NULL]){
            [fileManager createDirectoryAtPath:self.directory withIntermediateDirectories:YES attributes:nil error:nil];
        }
        [self loadCacheStore];
    }
    
    return self;
}

- (NSData *)dataForKey:(NSString *)key
{
    @synchronized(self) {
        NSString *filename = [self.cachedMap objectForKey:key];
        if (!filename) return nil;
        
        NSString *fullpath = [self filenameToPath:filename];
        
        NSData *data = [NSData dataWithContentsOfFile:fullpath];
        return data;
    }
}

- (void)setData:(NSData *)data forKey:(NSString *)key
{
    @synchronized(self) {
        [self cleanUpCache];
        NSString *filename = [self.cachedMap objectForKey:key];
        
        NSDateFormatter *format = [[NSDateFormatter alloc] init];
        [format setDateFormat:@"yyyy.MM.dd.HH.mm.ss.SSS"];
        filename = [format stringFromDate:[[NSDate alloc] init]];
        NSLog(@"key hash %u", [key hash]);
        
        self.currentCacheSize += [data length];
        [data writeToFile:[self filenameToPath:filename] atomically:YES];
        [self addDataToStoreWithKey:key andName:filename];
        [self saveCacheStore];
    }
}

- (void)clearCache
{
    NSFileManager *fileManager = [[NSFileManager alloc]init];
    
    for (NSInteger i = 0; i < self.cachedArray.count; i++) {
        NSString *key = [self.cachedArray objectAtIndex:i];
        NSString *filename = [self.cachedMap objectForKey:key];
        NSString *fullpath = [self filenameToPath:filename];
        [fileManager removeItemAtPath:fullpath error:nil];
    }
    [self.cachedArray removeAllObjects];
    [self.cachedMap removeAllObjects];
    self.currentCacheSize = 0;
    
    [self saveCacheStore];
}

- (void)saveCacheStore
{
    [self.cachedMap writeToFile:[self filenameToPath:CacheMapStore] atomically:YES];
    [self.cachedArray writeToFile:[self filenameToPath:CacheKeysStore] atomically:YES];
}

- (void)loadCacheStore
{
    self.cachedMap = [[NSDictionary dictionaryWithContentsOfFile:[self filenameToPath:CacheMapStore]] mutableCopy];
    self.cachedArray = [[NSArray arrayWithContentsOfFile:[self filenameToPath:CacheKeysStore]] mutableCopy];
    
    if (!self.cachedArray) self.cachedArray = [[NSMutableArray alloc]init];
    if (!self.cachedMap) self.cachedMap = [[NSMutableDictionary alloc]init];
}

- (void)cleanUpCache
{
    if (self.currentCacheSize >= self.maxCacheSize){
        
        NSFileManager *fileManager = [[NSFileManager alloc]init];
        
        long cacheSizeBound = self.currentCacheSize * 2 / 3;
        NSLog(@"recude to %ld", cacheSizeBound);
        long cacheSize = self.currentCacheSize;
        
        while (cacheSize > cacheSizeBound && self.cachedArray.count > 0) {
            NSString *key = [self.cachedArray objectAtIndex:0];
            NSString *fullpath = [self filenameToPath:[self.cachedMap objectForKey:key]];
            
            NSLog(@"delete file %@", [self.cachedMap objectForKey:key]);
            
            NSNumber *fileSize = [[fileManager attributesOfItemAtPath:fullpath error:nil] objectForKey:NSFileSize];
            NSLog(@"file attr %@", [fileManager attributesOfItemAtPath:fullpath error:nil]);
            cacheSize = cacheSize - [fileSize longLongValue];
            [self removeDataFromStoreWithKey:key];
            [fileManager removeItemAtPath:fullpath error:nil];
        }
        [self saveCacheStore];
        self.currentCacheSize = cacheSize;
    }
}

- (NSString *)filenameToPath:(NSString *)filename {
    
    NSString *fullpath = [[self.directory stringByAppendingPathComponent:filename] stringByAppendingString:@".cache"];
    return fullpath;
}

- (void)addDataToStoreWithKey:(NSString *)key andName:(NSString *)filename
{
    [self.cachedMap setObject:filename forKey:key];
    [self.cachedArray addObject:key];
}

- (void)removeDataFromStoreWithKey:(NSString *)key
{
    [self.cachedMap removeObjectForKey:key];
    [self.cachedArray removeObjectIdenticalTo:key];
}
@end
