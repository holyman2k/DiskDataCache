DiskDataCache
=============

I've created this library to help me store image file cache on disk for iOS projects and and couldn't find a libaries 
that uses disk as cache intead of in memory cache.  The purpose of this class is a general purpose cache that store data
in disk.  If you want to store frequently access data, maybe an in memory cache is better suited for you.

Usage
-----

first create a DiskDataCache instance by using the singleton class, optionally you can set the max bytes can be store
before older data gets removed.

  DiskDataCache *diskDataCache = [DiskDataCache globalInstant]

  [diskDataCache setMaxCacheSize];

to add and get data from cache
  
  [diskDataCache setData:data forKey:@"cache key"];  

  NSData *data = [diskDataCache dataForKey:@"cache key"];

to clear cache

  [diskDataCache clearCache];

some methods to get cache information

  [diskDataCache currentCacheSize];

  [diskDataCache currentCachedObjectCount];
  
