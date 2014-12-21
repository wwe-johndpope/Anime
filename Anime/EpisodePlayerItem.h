//
//  EpisodePlayerItem.h
//  Anime
//
//  Created by David Quesada on 12/21/14.
//  Copyright (c) 2014 David Quesada. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "Episode.h"
#import "Series.h"

@interface EpisodePlayerItem : AVPlayerItem

@property(readonly) Episode *episode;
@property(readonly) StreamQuality playbackQuality;

@end