//
//  KissAnimeEpisode.m
//  Anime
//
//  Created by David Quesada on 5/8/15.
//  Copyright (c) 2015 David Quesada. All rights reserved.
//

#import "KissAnimeEpisode.h"
#import "Episode_Private.h"
#import "HTMLReader.h"

@interface KissAnimeEpisode ()
{
    NSString *_episodeID, *_episodeDescription;
}
@end

@implementation KissAnimeEpisode

@synthesize episodeID = _episodeID, episodeDescription = _episodeDescription;

-(instancetype)initWithID:(NSString *)eID description:(NSString *)eDesc
{
    if ((self = [super init]))
    {
        _episodeID = eID;
        _episodeDescription = eDesc;
    }
    return self;
}

-(StreamQuality)_qualityForLinkText:(NSString *)text;
{
    // 1920x1024.mp4
    text = [text substringFromIndex:(1 + [text rangeOfString:@"x"].location)];
    // 1024.mp4
    text = [text substringToIndex:[text rangeOfString:@"."].location];
    // 1024
    
    NSInteger height = [text integerValue];
    
    return [self.class _qualityForVideoHeight:height];
}

-(void)fetchStreamURLs:(void (^)())completion
{
    NSURL *url = [NSURL URLWithString:@"http://kissanime.com/Mobile/GetEpisode"];
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:url];
    
    
    NSString *bodyString = [NSString stringWithFormat:@"eID=%@", self.episodeID];
    req.HTTPMethod = @"POST";
    req.HTTPBody = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    
    [NSURLConnection sendAsynchronousKissAnimeRequest:req queue:[NSOperationQueue new] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        data = [[NSData alloc] initWithBase64EncodedData:data options:0];
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        HTMLDocument *doc = [HTMLDocument documentWithString:string];
        
        id Links = [doc nodesMatchingSelector:@"a"];
        //        id LinkURLs = [[Links valueForKey:@"attributes"] valueForKey:@"href"];
        //        id LinkQualities = [Links valueForKey:@"textContent"];
        

        NSMutableArray *URLs = [NSMutableArray new];
        NSMutableArray *qualities = [NSMutableArray new];
        
        for (HTMLElement *link in Links)
        {
            id urlString = link.attributes[@"href"];
            id url = [NSURL URLWithString:urlString];
            id text = link.textContent;
            
            [URLs addObject:url];
            
            StreamQuality qual = [self _qualityForLinkText:text];
            [qualities addObject:@(qual)];
        }
        
        [self _setVideoStreams:URLs forQualities:qualities];
        
        if (completion)
            dispatch_async(dispatch_get_main_queue(), completion);
    }];
}

@end
