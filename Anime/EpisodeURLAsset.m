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
    
    return [metadata copy];
}

@end