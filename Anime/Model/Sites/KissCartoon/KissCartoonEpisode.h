//
//  KissCartoonEpisode.h
//  Anime
//
//  Created by David Quesada on 5/26/15.
//  Copyright (c) 2015 David Quesada. All rights reserved.
//

#import "Episode.h"

@class HTMLElement;

@interface KissCartoonEpisode : Episode

-(instancetype)initWithTableRow:(HTMLElement *)row seriesTitle:(NSString *)title;

@end
