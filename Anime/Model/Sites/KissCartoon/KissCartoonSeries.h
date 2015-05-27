//
//  KissCartoonSeries.h
//  Anime
//
//  Created by David Quesada on 5/26/15.
//  Copyright (c) 2015 David Quesada. All rights reserved.
//

#import "Series.h"

@class HTMLElement;

@interface KissCartoonSeries : Series

-(instancetype)initWithSeriesTR:(HTMLElement *)data;
-(instancetype)initWithDetailPage:(HTMLDocument *)page;

@end
