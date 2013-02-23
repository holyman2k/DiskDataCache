//
//  DiskDataCache.m
//  Tuli
//
//  Created by Charlie Wu on 29/01/13.
//  Copyright (c) 2013 Charlie Wu. All rights reserved.
//

#import "DiskDataCache.h"

@interface DiskDataCache()
@property (nonatomic) long maxCacheCount;
@property (nonatomic) long currentCacheCount;
@property (strong, atomic) NSMutableDictionary *cacheMap;
@property (strong, atomic) NSMutableArray *cacheMapOrder;
@property (strong, nonatomic) NSString *directory;
@end

@implementation DiskDataCache

static DiskDataCache *singleton = nil;

@synthesize maxCacheCount = _maxCacheCount;
@synthesize currentCacheCount = _currentCacheCount;
@synthesize cacheMap = _cacheMap;
@synthesize directory = _directory;

- (void)setCurrentCacheCount:(long)currentCacheCount
{
    _currentCacheCount = currentCacheCount;
    NSString *size = [NSString stringWithFormat:@"%ld", currentCacheCount];
    NSError *error;
    [size writeToFile:[self filenameToPath:@"currentSize.txt"] atomically:YES encoding:NSUTF8StringEncoding error:&error];
}

- (long)currentCacheCount
{
    if (!_currentCacheCount){
        NSError *error;
        NSString *value = [NSString stringWithContentsOfFile:[self filenameToPath:@"currentSize.txt"] encoding:NSUTF8StringEncoding error:&error];
        if (value) _currentCacheCount = [value longLongValue];
    }
    return _currentCacheCount;
}

+ (id) globalInstant
{
    @synchronized(self)
    {
        if (singleton == nil)
            singleton = [[self alloc] init];
    }
    
    return singleton;
}

- (id)init
{
    if (self = [super init])
    {
        self.maxCacheCount = DefaultCacheCount;
        self.directory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:DefaultCacheFolder];
        NSFileManager *fileManager = [[NSFileManager alloc]init];
        [fileManager createDirectoryAtPath:self.directory withIntermediateDirectories:YES attributes:nil error:nil];
        [self loadCacheMap];
        [self loadCacheMapOrder];
    }
    
    return self;
}

- (NSData *)dataForKey:(NSString *)key
{
    @synchronized(self) {
        NSString *filename = [self.cacheMap objectForKey:key];
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
        NSFileManager *fileManager = [[NSFileManager alloc]init];
        NSString *filename = [self.cacheMap objectForKey:key];
        
        if (!filename) { // new file
            NSDateFormatter *format = [[NSDateFormatter alloc] init];
            [format setDateFormat:@"yy-MM-dd-HH-mm-ss-SSS"];            
            filename = [format stringFromDate:[[NSDate alloc] init]];
        } else { // existing file
            
            NSString *fullpath = [self filenameToPath:filename];
            [fileManager removeItemAtPath:fullpath error:nil];
        }
        
        NSString *fullpath = [self filenameToPath:filename];        
        [data writeToFile:fullpath atomically:YES];
        [self.cacheMap setObject:filename forKey:key];
        [self saveCacheMap];
        
        [self.cacheMapOrder addObject:key];
        [self saveCacheMapOrder];
    }
}


- (void)saveCacheMap
{
    NSString *fullpath = [self filenameToPath:@"cacheMap.plist"];
    [self.cacheMap writeToFile:fullpath atomically:YES];
    self.currentCacheCount = self.currentCacheCount + 1;
}

- (void)loadCacheMap
{
    NSString *filepath = [self filenameToPath:@"cacheMap.plist"];
    self.cacheMap = [[NSDictionary dictionaryWithContentsOfFile:filepath] mutableCopy];
    
    if (!self.cacheMap) self.cacheMap = [[NSMutableDictionary alloc]init];
}

- (void)saveCacheMapOrder
{
    NSString *fullpath = [self filenameToPath:@"cacheMapOrder.plist"];
    [self.cacheMapOrder writeToFile:fullpath atomically:YES];
}

- (void)loadCacheMapOrder
{
    NSString *fullpath = [self filenameToPath:@"cacheMapOrder.plist"];
    self.cacheMapOrder = [[NSArray arrayWithContentsOfFile:fullpath] mutableCopy];
    
    if (!self.cacheMapOrder){
        self.cacheMapOrder = [[NSMutableArray alloc]init];
    }
}

- (void)cleanUpCache
{
    if (self.currentCacheCount >= self.maxCacheCount){
        
        NSFileManager *fileManager = [[NSFileManager alloc]init];
        
        int reduceCacheBy = self.maxCacheCount / 3;
        
        for (NSInteger i = 0; i < reduceCacheBy; i++) {
            NSString *key = [self.cacheMapOrder objectAtIndex:i];
            NSString *filename = [self.cacheMap objectForKey:key];
            NSString *fullpath = [self filenameToPath:filename];
            [self.cacheMap removeObjectForKey:key];
            [fileManager removeItemAtPath:fullpath error:nil];
        }
        [self.cacheMapOrder removeObjectsInRange: (NSRange){0, reduceCacheBy}];
        self.currentCacheCount = self.currentCacheCount - reduceCacheBy;
    }
}

- (NSString *)filenameToPath:(NSString *)filename {
    
    NSString *fullpath = [[self.directory stringByAppendingPathComponent:filename] stringByAppendingString:@".cache"];
    return fullpath;
}

@end
