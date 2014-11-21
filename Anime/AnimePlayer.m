//
//  AnimePlayer.m
//  Anime
//
//  Created by David Quesada on 11/10/14.
//  Copyright (c) 2014 David Quesada. All rights reserved.
//

#import "AnimePlayer.h"
#import "Episode.h"
#import "Series.h"
#import "Recents.h"

@interface EpisodePlayerItem()
// Assumes the urls for the episode stream are already fetched.
-(instancetype)initWithEpisode:(Episode *)ep desiredQuality:(StreamQuality)quality;
@end


@implementation EpisodePlayerItem
-(instancetype)initWithEpisode:(Episode *)ep desiredQuality:(StreamQuality)quality
{
    StreamQuality actual = StreamQualityUnknown;
    NSURL *url = [ep streamURLOfMaximumQuality:quality actualQuality:&actual];
    
    if ((self = [super initWithURL:url]))
    {
        _episode = ep;
        _playbackQuality = actual;
    }
    return self;
}
@end


@interface AnimePlayer ()
{
    Series *_series;
    Episode *_episode;
    NSMutableArray *_episodeQueue;
}
+(void)playerDidPlayToEnd:(NSNotification *)note;
+(StreamQuality)defaultStreamQuality;
@end

@implementation AnimePlayer

+(void)load
{
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

+(StreamQuality)defaultStreamQuality
{
    NSNumber *val = [[NSUserDefaults standardUserDefaults] valueForKey:@"DefaultEpisodeStreamQuality"];
    
    if (!val || !val.integerValue)
        return StreamQualityMaxAvailable;
    
    return (StreamQuality)[val integerValue];
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        [self addObserver:self forKeyPath:@"rate" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) context:nil];
        [self addObserver:self forKeyPath:@"currentItem" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) context:nil];
    }
    return self;
}

-(void)dealloc
{
    [self removeObserver:self forKeyPath:@"rate"];
    [self removeObserver:self forKeyPath:@"currentItem"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"rate"])
    {
        if (self.rate)
        {
            if ([self.delegate respondsToSelector:@selector(animePlayerDidPlay:)])
                [self.delegate animePlayerDidPlay:self];
        } else
        {
            if ([self.delegate respondsToSelector:@selector(animePlayerDidPause:)])
                [self.delegate animePlayerDidPause:self];
        }
    }
    else if ([keyPath isEqualToString:@"currentItem"])
    {
        // Queue the next item.
        if (self.currentItem)
            [self addItemToPlayerQueueWithStartTime:0.0 completion:nil];
        
        if ([self.delegate respondsToSelector:@selector(animePlayer:didChangeItem:)])
            [self.delegate animePlayer:self didChangeItem:(id)self.currentItem];
    }
}

+(void)playerDidPlayToEnd:(NSNotification *)note
{
    AnimePlayer *player = note.object;
    if ([player.delegate respondsToSelector:@selector(animePlayerDidFinishPlayback:)])
        [player.delegate animePlayerDidFinishPlayback:player];
}

+(instancetype)playerWithWatch:(RecentWatch *)watch
{
    AnimePlayer *player = [[self alloc] init];
    [player setWatch:(RecentWatch *)watch];
    
    return player;
}

+(instancetype)playerWithSeries:(Series *)series episode:(Episode *)episode
{
    AnimePlayer *player = [[self alloc] init];
    [player setSeries:series episode:episode];
    return player;
}

-(void)addItemToPlayerQueueWithStartTime:(NSTimeInterval)startTime completion:(void (^)())completion
{
    if (!_episodeQueue.count)
    {
        NSLog(@"No more episodes to add to queue.");
        return;
    }
    Episode *ep = [_episodeQueue firstObject];
    [_episodeQueue removeObjectAtIndex:0];
    
#if 1
// Old way of doing things.
    
    StreamQuality q = [self.class defaultStreamQuality];
    [ep fetchStreamURLs:^{
    
//        NSURL *url = [ep streamURLOfMaximumQuality:q];
//        EpisodePlayerItem *item = [[EpisodePlayerItem alloc] initWithURL:url];
//        item.episode = ep;
  
        EpisodePlayerItem *item = [[EpisodePlayerItem alloc] initWithEpisode:ep desiredQuality:q];
        [item seekToTime:CMTimeMakeWithSeconds((Float64)startTime, 1)];
        
#warning Exception here.
        [self insertItem:item afterItem:nil];
        
        if (completion)
            dispatch_async(dispatch_get_main_queue(), completion);
        
    }];
    

#else
    // Thing from stackoverflow
    [ep fetchVideoURLs:^(NSArray *urls) {
        NSString *url = urls.firstObject;
        
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL URLWithString:url] options:nil];
        NSArray *keys = @[@"playable", @"tracks",@"duration" ];
        
        EpisodePlayerItem *item = [[EpisodePlayerItem alloc] initWithAsset:asset];
        item.episode = ep;
        
        [asset loadValuesAsynchronouslyForKeys:keys completionHandler:^()
         {
             // make sure everything downloaded properly
             for (NSString *thisKey in keys) {
                 NSError *error = nil;
                 AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
                 if (keyStatus == AVKeyValueStatusFailed) {
                     return ;
                 }
             }
             
//             EpisodePlayerItem *item = [[EpisodePlayerItem alloc] initWithAsset:asset];
//             item.episode = ep;
             
             dispatch_async(dispatch_get_main_queue(), ^ {
                 [self insertItem:item afterItem:nil];
                 
                 if (completion)
                     completion();
             });
         }];
    }];
//        [item seekToTime:CMTimeMakeWithSeconds((Float64)startTime, 1)];
#endif
}

-(void)addNumberOfItemsToPlayerQueue:(NSInteger)count
{
    if (count <= 0)
        return;
    
    __weak id wself = self;
    [self addItemToPlayerQueueWithStartTime:0.0 completion:^{
        __strong id sself = wself;
        [sself addNumberOfItemsToPlayerQueue:count - 1];
    }];
}

-(void)setWatch:(RecentWatch *)watch
{
    [Series fetchSeriesWithID:watch.seriesID completion:^(Series *series) {
        
        _series = series;
        id _id = watch.episodeID;
        for (NSUInteger idx = 0; idx < [series.episodes count]; ++idx)
        {
            if ([[series.episodes[idx] episodeID] isEqualToString:_id])
            {
                _episodeQueue = [series.episodes subarrayWithRange:NSMakeRange(idx, series.episodes.count - idx)].mutableCopy;
                _episode = _episodeQueue[0];
            }
        }
        
#warning Get a better way to handle this, whatever it means.
        NSAssert(_episode, @"Couldn't find the episode");
        
        [self addItemToPlayerQueueWithStartTime:watch.seekTime completion:^{
            [self addNumberOfItemsToPlayerQueue:2];
          }];
    }];
}

-(void)setSeries:(Series *)series episode:(Episode *)episode
{
    _series = series;
    
    [series fetchEpisodes:^{

        NSMutableArray *q = nil;
        for (NSUInteger i = 0; i < series.episodes.count; ++i)
        {
            if ([[series.episodes[i] episodeID] isEqualToString:episode.episodeID])
            {
                q = [series.episodes subarrayWithRange:NSMakeRange(i, series.episodes.count - i)].mutableCopy;
                break;
            }
        }
        
        NSAssert(q, @"Couldn't create episode queue");
        _episodeQueue = q;
        
        [self addItemToPlayerQueueWithStartTime:0 completion:^{
            [self addNumberOfItemsToPlayerQueue:2];
        }];
    }];
}

//+playerwi

@end
