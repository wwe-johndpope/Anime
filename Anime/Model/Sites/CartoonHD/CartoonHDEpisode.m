//
//  CartoonHDEpisode.m
//  Anime
//
//  Created by David Quesada on 4/9/15.
//  Copyright (c) 2015 David Quesada. All rights reserved.
//

#import "CartoonHDEpisode.h"
#import "Episode_Private.h"

@interface CartoonHDEpisode ()
{
    NSString *_episodeID;
    NSString *_episodeDescription;
}

@end

@implementation CartoonHDEpisode

@synthesize episodeID=_episodeID, episodeDescription=_episodeDescription;

-(instancetype)initWithJSON:(NSDictionary *)json
{
    if ((self = [super init]))
        [self _setJSON:json];
    return self;
}

-(void)_setJSON:(NSDictionary *)json
{
    _episodeID = json[@"film_id"];
    _episodeDescription = json[@"film_name"];
    
//    NSString *
    // The links come in the format "url1#quality1#url2#quality2#"
    NSString *linksData = json[@"film_link"];
    NSArray *parts = [linksData componentsSeparatedByString:@"#"];
    
    NSMutableArray *urls = [NSMutableArray new];
    NSMutableArray *qualities = [NSMutableArray new];
    
    // Subtract 1 from the length because the string ends in an extra #,
    // which means there's an empty string at the end of the array.
    for (int i = 0; i < parts.count - 1; i += 2)
    {
        [urls addObject:[NSURL URLWithString:parts[i]]];
        [qualities addObject:@([self.class _qualityForVideoHeight:[parts[i+1] integerValue]])];
    }

    [self _setVideoStreams:urls.copy forQualities:qualities.copy];
}

-(void)fetchStreamURLs:(void (^)())completion
{
    if (completion)
        [[NSOperationQueue mainQueue] addOperationWithBlock:completion];
}

@end
