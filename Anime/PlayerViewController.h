//
//  PlayerViewController.h
//  Anime
//
//  Created by David Quesada on 11/9/14.
//  Copyright (c) 2014 David Quesada. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Episode.h"
@import AVKit;

@class Series, RecentWatch;

//@interface PlayerViewController : MPMoviePlayerViewController
@interface PlayerViewController : AVPlayerViewController

-(instancetype)initWithSeries:(Series *)series episode:(Episode *)episode;
-(instancetype)initWithWatch:(RecentWatch *)watch;

@property(nonatomic) StreamQuality preferredStreamQuality;

@end
