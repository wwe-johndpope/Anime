//
//  CartoonHDMovieSeriesRequest.m
//  Anime
//
//  Created by David Quesada on 5/7/15.
//  Copyright (c) 2015 David Quesada. All rights reserved.
//

#import "CartoonHDMovieSeriesRequest.h"
#import "CartoonHDSeries_Private.h"
#import "CartoonHDMovieSeries.h"

@implementation CartoonHDMovieSeriesRequest

#pragma mark - CartoonHDSeriesRequest API

+(Class)cartoonHDSeriesClass
{
    return [CartoonHDMovieSeries class];
}

@end
