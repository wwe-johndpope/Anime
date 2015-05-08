//
//  Episode_Private.h
//  Anime
//
//  Created by David Quesada on 5/8/15.
//  Copyright (c) 2015 David Quesada. All rights reserved.
//

#import "Episode.h"

@interface Episode ()

+(StreamQuality)_qualityForVideoHeight:(NSInteger)val;
-(void)_setVideoStreams:(NSArray *)urls forQualities:(NSArray *)qualities;

@end
