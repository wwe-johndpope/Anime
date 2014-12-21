//
//  EpisodeURLAsset.h
//  Anime
//
//  Created by David Quesada on 12/21/14.
//  Copyright (c) 2014 David Quesada. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "Series.h"
#import "Episode.h"

@interface EpisodeURLAsset : AVURLAsset

-(instancetype)initWithEpisode:(Episode *)ep inSeries:(Series *)series quality:(StreamQuality)quality;

@property(readonly) StreamQuality playbackQuality;

@end
