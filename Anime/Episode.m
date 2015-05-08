//
//  Episode.m
//  Anime
//
//  Created by David Quesada on 11/9/14.
//  Copyright (c) 2014 David Quesada. All rights reserved.
//

#import "Episode.h"
#import "Episode_Private.h"

@implementation Episode

#pragma mark - Stubs. To be overridden in subclasses.

-(void)fetchStreamURLs:(void (^)())completion { }

#pragma mark - Default implementations

-(NSURL *)streamURLForVideoQuality:(StreamQuality)quality
{
    return self.urlsByVideoQuality[@(quality)];
}

-(NSURL *)streamURLOfMaximumQuality:(StreamQuality)quality actualQuality:(StreamQuality *)actualQuality
{
    for (NSNumber *num in self.allStreamQualities.reverseObjectEnumerator)
    {
        if (num.integerValue <= (NSInteger)quality)
        {
            if (actualQuality)
                *actualQuality = (StreamQuality)num.integerValue;
            return self.urlsByVideoQuality[num];
        }
    }
    
    if (actualQuality)
        *actualQuality = (StreamQuality)[self.allStreamQualities.firstObject integerValue];
    return self.allStreamURLs.firstObject;
}

-(NSURL *)streamURLOfMaximumQuality:(StreamQuality)quality
{
    return [self streamURLOfMaximumQuality:quality actualQuality:NULL];
}

-(NSURL *)streamURLOfMinimumQuality:(StreamQuality)quality
{
    return self.allStreamURLs.lastObject;
}

-(NSURL *)highestQualityStream
{
    return self.allStreamURLs.lastObject;
}

#pragma mark - Private

+(StreamQuality)_qualityForVideoHeight:(NSInteger)val
{
    if (val <= 160)
        return StreamQualityUnknown;
    if (val <= 260)
        return StreamQuality240;
    if (val <= 500)
        return StreamQuality360;
    if (val <= 770)
        return StreamQuality720;
    
    if (val > 1080)
        NSLog(@"Super HD stream quality: %d", val);
    
    return StreamQuality1080;
}

// Sets the lists of video streams and qualities. The qualities will be sorted in ascending order.
-(void)_setVideoStreams:(NSArray *)urls forQualities:(NSArray *)qualities
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:urls forKeys:qualities];
    
    _urlsByVideoQuality = dict;
    _allStreamQualities = [dict.allKeys sortedArrayUsingSelector:@selector(compare:)];
    _allStreamURLs = [dict objectsForKeys:_allStreamQualities notFoundMarker:[NSNull null]];
}

@end
