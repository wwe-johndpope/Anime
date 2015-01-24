//
//  EpisodePlayerItem.m
//  Anime
//
//  Created by David Quesada on 12/21/14.
//  Copyright (c) 2014 David Quesada. All rights reserved.
//

#import "EpisodePlayerItem.h"
#import "EpisodeURLAsset.h"

@interface EpisodePlayerItem()
// Assumes the urls for the episode stream are already fetched.
-(instancetype)initWithEpisode:(Episode *)ep inSeries:(Series *)series desiredQuality:(StreamQuality)quality;
@end

@implementation EpisodePlayerItem

-(instancetype)initWithEpisode:(Episode *)ep inSeries:(Series *)series desiredQuality:(StreamQuality)quality
{
    EpisodeURLAsset *asset = [[EpisodeURLAsset alloc] initWithEpisode:ep inSeries:series quality:quality];
    if ((self = [self initWithAsset:asset]))
    {
        _series = series;
        _episode = ep;
        _playbackQuality = asset.playbackQuality;
    }
    return self;
}

@end