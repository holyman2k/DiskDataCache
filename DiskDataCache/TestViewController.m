//
//  TestViewController.m
//  DiskDataCache
//
//  Created by Charlie Wu on 26/02/13.
//  Copyright (c) 2013 Charlie Wu. All rights reserved.
//

#import "TestViewController.h"
#import "DiskDataCache.h"
#import <dispatch/dispatch.h>
@interface TestViewController ()
@property (strong, nonatomic) DiskDataCache *cache;

@end

@implementation TestViewController

@synthesize statusLabel, saveBlobCount;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.cache = [DiskDataCache globalInstant];
//    [self.cache setMaxCacheSize:10000];
}

- (IBAction)setBlobCount:(UISlider *)sender
{
    self.saveBlobCount.text = [NSString stringWithFormat:@"%d", (int)sender.value];
}
- (IBAction)createCache:(id)sender
{
    int count = [self.saveBlobCount.text intValue];
    NSMutableDictionary *blobs = [NSMutableDictionary dictionaryWithCapacity:count];
    
    while (count > 0) {
        NSString *key = [self randomStringWithLength:20];
        NSString *value = [self randomStringWithLength:500];
        
        [blobs setObject:value forKey:key];
        count --;
    }
    
    for (NSString *key in blobs) {
        dispatch_queue_t queue = dispatch_queue_create("key", NULL);
        dispatch_async(queue, ^{
            NSString *value = [blobs objectForKey:key];
            NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
            [self.cache setData:data forKey:key];
        });
    }
//    [self updateCacheStatus:nil];
}
- (IBAction)clearCache:(id)sender
{
    [self.cache clearCache];
}
- (IBAction)updateCacheStatus:(id)sender
{
    self.statusLabel.text = [NSString stringWithFormat:@"objects stored: %d total of %ld", [self.cache currentCachedObjectCount], [self.cache currentCacheSize]];
}
- (IBAction)validateCache:(id)sender
{
    statusLabel.text = [self.cache validateCache] ? @"valid" : @"contain invalid cache";
}

NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

-(NSString *) randomStringWithLength: (int) len {
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
    }
    
    return randomString;
}

@end
