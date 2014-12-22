//
//  Episode.m
//  Anime
//
//  Created by David Quesada on 11/9/14.
//  Copyright (c) 2014 David Quesada. All rights reserved.
//

#import "Episode.h"
#import "HTMLReader.h"

@interface Episode ()
{
    NSDictionary *_urlsByVideoQuality;
}

@end

@implementation Episode

-(instancetype)initWithID:(NSString *)eID description:(NSString *)eDesc
{
    if ((self = [super init]))
    {
        _episodeID = eID;
        _episodeDescription = eDesc;
    }
    return self;
}

-(StreamQuality)qualityForLinkText:(NSString *)text;
{
    NSString *orig = text;
    
    // 1920x1024.mp4
    text = [text substringFromIndex:(1 + [text rangeOfString:@"x"].location)];
    // 1024.mp4
    text = [text substringToIndex:[text rangeOfString:@"."].location];
    // 1024
    
    NSInteger height = [text integerValue];
    
    if (height <= 160)
        return StreamQualityUnknown;
    if (height <= 260)
        return StreamQuality240;
    if (height <= 500)
        return StreamQuality360;
    if (height <= 770)
        return StreamQuality720;
    
    if (height > 1080)
        NSLog(@"Super HD stream quality: %@", orig);
    
    return StreamQuality1080;
}

-(void)fetchStreamURLs:(void (^)())completion
{
    NSURL *url = [NSURL URLWithString:@"http://kissanime.com/Mobile/GetEpisode"];
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:url];
    
    
    NSString *bodyString = [NSString stringWithFormat:@"eID=%@", self.episodeID];
    req.HTTPMethod = @"POST";
    req.HTTPBody = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue new] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        

        
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        HTMLDocument *doc = [HTMLDocument documentWithString:string];
        
        id Links = [doc nodesMatchingSelector:@"a"];
//        id LinkURLs = [[Links valueForKey:@"attributes"] valueForKey:@"href"];
//        id LinkQualities = [Links valueForKey:@"textContent"];
        
        
        NSMutableDictionary *dict = [NSMutableDictionary new];
        NSMutableArray *allURLs = [NSMutableArray new];
        
        for (HTMLElement *link in Links)
        {
            id urlString = link.attributes[@"href"];
            id url = [NSURL URLWithString:urlString];
            id text = link.textContent;
            
            [allURLs addObject:url];
            
            StreamQuality qual = [self qualityForLinkText:text];
            dict[@(qual)] = url;
        }
        
        _urlsByVideoQuality = dict.copy;
        _allStreamURLs = allURLs.copy;
        _allStreamQualities = [dict.allKeys sortedArrayUsingSelector:@selector(compare:)];
        
        if (completion)
            dispatch_async(dispatch_get_main_queue(), completion);
    }];
}

-(void)fetchVideoURLs:(void (^)(NSArray *))completion
{
    [self fetchStreamURLs:^{
        if (completion)
            completion(_allStreamURLs);
    }];
}

-(NSURL *)streamURLForVideoQuality:(StreamQuality)quality
{
    return _urlsByVideoQuality[@(quality)];
}

-(NSURL *)streamURLOfMaximumQuality:(StreamQuality)quality actualQuality:(StreamQuality *)actualQuality
{
    for (NSNumber *num in _allStreamQualities.reverseObjectEnumerator.allObjects)
    {
        if (num.integerValue <= (NSInteger)quality)
        {
            if (actualQuality)
                *actualQuality = (StreamQuality)num.integerValue;
            return _urlsByVideoQuality[num];
        }
    }
    
    if (actualQuality)
        *actualQuality = StreamQualityMinUsed;
    return _allStreamURLs.lastObject;
}

-(NSURL *)streamURLOfMaximumQuality:(StreamQuality)quality
{
    return [self streamURLOfMaximumQuality:quality actualQuality:NULL];
}

-(NSURL *)streamURLOfMinimumQuality:(StreamQuality)quality
{
    // Makes the assumption that the site always puts the higher quality streams first.
    return _allStreamURLs.firstObject;
}

@end
