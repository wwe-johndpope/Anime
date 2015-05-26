//
//  EpisodeURLAsset.m
//  Anime
//
//  Created by David Quesada on 12/21/14.
//  Copyright (c) 2014 David Quesada. All rights reserved.
//

#import "EpisodeURLAsset.h"

@interface EpisodeURLAsset ()

@property(readonly) Episode *episode;
@property(readonly) Series *series;

@end

@implementation EpisodeURLAsset

-(instancetype)initWithEpisode:(Episode *)ep inSeries:(Series *)series quality:(StreamQuality)quality
{
    StreamQuality actual = StreamQualityUnknown;
    NSURL *url = [ep streamURLOfMaximumQuality:quality actualQuality:&actual];
    
    if ((self = [super initWithURL:url options:@{}]))
    {
        _episode = ep;
        _series = series;
        _playbackQuality = actual;
    }
    
    return self;
}

-(NSArray *)commonMetadata
{
    NSMutableArray *metadata = [NSMutableArray new];
    
    if (self.episode.episodeDescription)
    {
        AVMutableMetadataItem *item = [[AVMutableMetadataItem alloc] init];
        item.keySpace = AVMetadataKeySpaceCommon;
        item.key = AVMetadataCommonKeyTitle;
        item.value = self.episode.episodeDescription;
        
        [metadata addObject:item];
    }
    
    if (self.series.seriesTitle)
    {
        AVMutableMetadataItem *item = [[AVMutableMetadataItem alloc] init];
        item.keySpace = AVMetadataKeySpaceCommon;
        // For some reason, using AlbumName doesn't work to get it to show in the now playing center.
        item.key = AVMetadataCommonKeyArtist;
        item.value = self.series.seriesTitle;
        
        [metadata addObject:item];
    }

    if (self.series.seriesImage)
    {
        AVMutableMetadataItem *item = [AVMutableMetadataItem new];
        item.keySpace = AVMetadataKeySpaceCommon;
        item.key = AVMetadataCommonKeyArtwork;
        item.value = UIImagePNGRepresentation(self.series.seriesImage);
        
        [metadata addObject:item];
    }
    
    return [metadata copy];
}

-(void)loadValuesAsynchronouslyForKeys:(NSArray *)keys completionHandler:(void (^)(void))handler
{
    if ([keys isEqualToArray:@[ @"commonMetadata" ]] && self.series)
    {
        // When we're loading the metadata, we want to do two things asynchronously.
        // In addition to the super call, we'd also like to load the series image. (if needed)
        
        // As a handler for each of the calls, we check to see if the other is done.
        NSLock *lock = [[NSLock alloc] init];
        __block int count = 2;
        
        void (^subhandler)() = ^{
            [lock lock];
            if (!--count)
                handler();
            [lock unlock];
        };
        
        [super loadValuesAsynchronouslyForKeys:keys completionHandler:subhandler];
        [self.series fetchImage:^(BOOL success, NSError *error) { subhandler(); }];
    }
    else
        [super loadValuesAsynchronouslyForKeys:keys completionHandler:handler];
}

@end