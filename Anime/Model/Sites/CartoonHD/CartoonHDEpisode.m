//
//  CartoonHDEpisode.m
//  Anime
//
//  Created by David Quesada on 4/9/15.
//  Copyright (c) 2015 David Quesada. All rights reserved.
//

#import "CartoonHDEpisode.h"

@interface CartoonHDEpisode ()
{
    NSString *_episodeID;
    NSString *_episodeDescription;
    
    NSArray *_allStreamQualities;
    NSArray *_allStreamURLs;
    NSDictionary *_urlsByVideoQuality;
}

@end

@implementation CartoonHDEpisode

@synthesize episodeID=_episodeID, episodeDescription=_episodeDescription, allStreamQualities=_allStreamQualities, allStreamURLs=_allStreamURLs, urlsByVideoQuality=_urlsByVideoQuality;

-(instancetype)initWithJSON:(NSDictionary *)json
{
    if ((self = [super init]))
        [self _setJSON:json];
    return self;
}

-(StreamQuality)_qualityForInteger:(NSInteger)val
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
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    // Subtract 1 from the length because the string ends in an extra #,
    // which means there's an empty string at the end of the array.
    for (int i = 0; i < parts.count - 1; i += 2)
    {
        [urls addObject:[NSURL URLWithString:parts[i]]];
        [qualities addObject:@([self _qualityForInteger:[parts[i+1] integerValue]])];
        
        dict[qualities.lastObject] = urls.lastObject;
    }

    _allStreamURLs = urls.copy;
    _allStreamQualities = qualities.copy;
    _urlsByVideoQuality = dict.copy;
}

-(void)fetchStreamURLs:(void (^)())completion
{
    if (completion)
        [[NSOperationQueue mainQueue] addOperationWithBlock:completion];
}

@end
