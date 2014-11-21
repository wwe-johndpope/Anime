//
//  Recents.m
//  Anime
//
//  Created by David Quesada on 11/9/14.
//  Copyright (c) 2014 David Quesada. All rights reserved.
//

#import "Recents.h"
#import "Series.h"
#import "Episode.h"

NSString * const ThumbnailDidChangeNotification = @"ThumbnailDidChangeNotification";
NSString * const ThumbnailSeriesKey = @"ThumbnailSeriesKey";
NSString * const ThumbnailImageKey = @"ThumbnailImageKey";

NSString * const RecentsWasChangedNotification = @"RecentsWasChangedNotification";


@interface RecentWatch () <NSCoding>
@property(readwrite) NSString *seriesID;
@property(readwrite) NSString *seriesTitle;
@property(readwrite) NSString *episodeID;
@property(readwrite) NSString *episodeTitle;
@property(readwrite) NSTimeInterval seekTime;
@property(readwrite) UIImage *cachedThumbnail;


-(void)writeCachedImage;

+(void)writeImage:(UIImage *)image forThumbnailForSeriesID:(NSString *)seriesID;
+(UIImage *)readImageForSeriesID:(NSString *)seriesID;

+(NSString *)_thumbnailFilePathForSeriesID:(NSString *)seriesID;

@end

@implementation RecentWatch

#pragma mark - Coding

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_seriesID forKey:@"seriesID"];
    [aCoder encodeObject:_seriesTitle forKey:@"seriesTitle"];
    [aCoder encodeObject:_episodeID forKey:@"episodeID"];
    [aCoder encodeObject:_episodeTitle forKey:@"episodeTitle"];
    [aCoder encodeDouble:_seekTime forKey:@"seekTime"];
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super init]))
    {
        _seriesID = [aDecoder decodeObjectForKey:@"seriesID"];
        _seriesTitle = [aDecoder decodeObjectForKey:@"seriesTitle"];
        _episodeID = [aDecoder decodeObjectForKey:@"episodeID"];
        _episodeTitle = [aDecoder decodeObjectForKey:@"episodeTitle"];
        _seekTime = [aDecoder decodeDoubleForKey:@"seekTime"];
    }
    return self;
}

#pragma mark - Public Stuff

-(void)fetchThumbnailWithCompletion:(void (^)())completion
{
    static NSOperationQueue *thumbnailReadQueue = nil;
    
    if (!thumbnailReadQueue)
    {
        thumbnailReadQueue = [[NSOperationQueue alloc] init];
        thumbnailReadQueue.name = @"Recents Thumbnail loading queue.";
    }
    
    // This is probably really ugly creating a new queue just for one operation.
    [thumbnailReadQueue addOperationWithBlock:^{
        _cachedThumbnail = [self.class readImageForSeriesID:self.seriesID];
        
        if (completion)
            [[NSOperationQueue mainQueue] addOperationWithBlock:completion];
    }];
}

-(Episode *)makeEpisode
{
    return [[Episode alloc] initWithID:self.episodeID description:self.episodeTitle];
}

#pragma mark - Other Stuff

+(void)writeImage:(UIImage *)image forThumbnailForSeriesID:(NSString *)seriesID
{
    // TODO: Scale down the image to save space if it's full size?
//    NSData *data = UIImagePNGRepresentation(image);
    
    NSData *data = UIImageJPEGRepresentation(image, 0.8f);
    
    NSString *path = [self _thumbnailFilePathForSeriesID:seriesID];
    [data writeToFile:path atomically:YES];
}

+(UIImage *)readImageForSeriesID:(NSString *)seriesID
{
    NSString *path = [self _thumbnailFilePathForSeriesID:seriesID];
    NSData *data = [NSData dataWithContentsOfFile:path];
    
    if (!data)
        return nil;
    
    return [UIImage imageWithData:data];
}

+(NSString *)_thumbnailFilePathForSeriesID:(NSString *)seriesID
{
    NSString *cachesDirectory = (id)NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    cachesDirectory = [(id)cachesDirectory firstObject];
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSString *appCacheDirectory = [cachesDirectory stringByAppendingPathComponent:bundleID];
    NSString *directory = [appCacheDirectory stringByAppendingPathComponent:@"Thumbnails"];
    [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    return [directory stringByAppendingPathComponent:seriesID];
}

-(void)writeCachedImage
{
    NSAssert(_cachedThumbnail, @"RecentWatch must have a cached thumbnail");
    [self.class writeImage:_cachedThumbnail forThumbnailForSeriesID:_seriesID];
}

@end




@interface Recents ()
{
    NSArray *_watches;
    NSOperationQueue *backgroundQueue;
    
    RecentWatch *currentWatch;
}

-(RecentWatch *)promoteOrAddSeries:(Series *)series;
-(RecentWatch *)watchForSeries:(Series *)series;
-(void)syncEvent; // Called when something happens that modifies the state and will need to by sync'd to disk eventually.

@end

@implementation Recents

+(instancetype)defaultRecentStore
{
    static Recents *rec = nil;
    if (!rec)
        rec = [[self alloc] init];
    return rec;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        backgroundQueue = [[NSOperationQueue alloc] init];
        _watches = [NSArray new];
    }
    return self;
}

-(RecentWatch *)promoteOrAddSeries:(Series *)series
{
    NSMutableArray *arr = [_watches mutableCopy];
    RecentWatch *target = nil;
    for (NSUInteger idx = 0; idx < arr.count; idx++)
    {
        RecentWatch *watch = arr[idx];
        if ([watch.seriesID isEqualToString:series.seriesID])
        {
            target = watch;
            [arr removeObjectAtIndex:idx];
            break;
        }
    }
    
    if (!target)
    {
        target = [RecentWatch new];
        target.seriesID = series.seriesID;
        target.seriesTitle = series.seriesTitle;
    }
    
    [arr insertObject:target atIndex:0];
    _watches = [arr copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:RecentsWasChangedNotification object:nil];
    
    return target;
}

-(RecentWatch *)watchForSeries:(Series *)series
{
    for (NSUInteger idx = 0; idx < _watches.count; idx++)
    {
        RecentWatch *watch = _watches[idx];
        if ([watch.seriesID isEqualToString:series.seriesID])
        {
            return watch;
        }
    }
    return nil;
}

+(NSString *)archiveFilePath
{
    NSArray *docsDirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = docsDirs.firstObject;
    return [path stringByAppendingPathComponent:@"Recents"];
}

+(void)loadRecents
{
    Recents *r = [self defaultRecentStore];
    NSArray *arr = [NSKeyedUnarchiver unarchiveObjectWithFile:[self archiveFilePath]];
    
    if (arr)
        r->_watches = arr;
    
    for (RecentWatch *w in arr)
         [w fetchThumbnailWithCompletion:nil];
}

-(void)syncEvent
{
    static NSOperationQueue * syncQueue = nil;
    
    if (!syncQueue)
    {
        syncQueue = [[NSOperationQueue alloc] init];
        syncQueue.name = @"Recents sync queue";
    }
    
    [syncQueue addOperationWithBlock:^{
        NSLog(@"Syncing recents.");
        [NSKeyedArchiver archiveRootObject:_watches toFile:[self.class archiveFilePath]];
    }];
}

-(void)setActiveSeries:(Series *)series episode:(Episode *)episode
{
//    NSAssert(!currentWatch, @"-[setThumbnail:]: curentWatch must be nil");
    
    RecentWatch *watch = [self promoteOrAddSeries:series];
    watch.episodeID = episode.episodeID;
    watch.episodeTitle = episode.episodeDescription;
    currentWatch = watch;
    
    [self syncEvent];
}

-(void)setThumbnail:(UIImage *)image forSeries:(Series *)series
{
//    NSAssert(currentWatch, @"-[setThumbnail:]: curentWatch must be non-nil");
    if (!image)
        return;
    
    RecentWatch *watch = [self watchForSeries:series];
    
    if (!watch)
        return;
    
    watch.cachedThumbnail = image;
    
    [backgroundQueue addOperationWithBlock:^{
        [watch writeCachedImage];
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ThumbnailDidChangeNotification object:watch userInfo:@{
                                                                                                                      ThumbnailImageKey: image,
                                                                                                                      ThumbnailSeriesKey: series,
                                                                                                                    }];
}

-(void)setSeekTime:(NSTimeInterval)time
{
//    NSAssert(currentWatch, @"-[setSeekTime:]: currentWatch must be non-nil");
    currentWatch.seekTime = time;
    [self syncEvent];
}

-(void)clearWatchedSeries
{
//    NSAssert(currentWatch, @"-[clearWatchedSeries]: curentWatch must be non-nil");
    currentWatch = nil;
    // We probably don't actually need this.
//    [self syncEvent];
}

-(void)removeWatch:(RecentWatch *)watch
{
    // This is pretty stupid that this is how I have to do this.
    NSMutableArray *watches = _watches.mutableCopy;
    [watches removeObjectIdenticalTo:watch];
    _watches = watches.copy;
    
    [self syncEvent];
}

@end
