//
//  AnimePlayer.h
//  Anime
//
//  Created by David Quesada on 11/10/14.
//  Copyright (c) 2014 David Quesada. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "Episode.h"

@class RecentWatch, Series;

@interface EpisodePlayerItem : AVPlayerItem
@property(readonly) Episode *episode;
@property(readonly) StreamQuality playbackQuality;
@end

@class AnimePlayer;

@protocol AnimePlayerDelegate <NSObject>
@optional
-(void)animePlayerDidFinishPlayback:(AnimePlayer *)player;
-(void)animePlayerDidPause:(AnimePlayer *)player;
-(void)animePlayerDidPlay:(AnimePlayer *)player;

-(void)animePlayer:(AnimePlayer *)player didChangeItem:(EpisodePlayerItem *)item;
@end


@interface AnimePlayer : AVQueuePlayer

+(instancetype)playerWithWatch:(RecentWatch *)watch;
+(instancetype)playerWithSeries:(Series *)series episode:(Episode *)episode;

@property(weak) id<AnimePlayerDelegate> delegate;

@end
