//
//  KissCartoonEpisode.m
//  Anime
//
//  Created by David Quesada on 5/26/15.
//  Copyright (c) 2015 David Quesada. All rights reserved.
//

#import "KissCartoonEpisode.h"
#import "HTMLReader.h"
#import "Episode_Private.h"
#import "NSURLConnection+KissAnime.h"

@interface KissCartoonEpisode ()
{
    NSString *_episodeID, *_episodeDescription;
}
-(void)setStreamURLsFromDetailPage:(HTMLDocument *)document;
@end

@implementation KissCartoonEpisode

@synthesize episodeID = _episodeID, episodeDescription = _episodeDescription;

-(instancetype)initWithTableRow:(HTMLElement *)row seriesTitle:(NSString *)seriesTitle
{
    if ((self = [super init]))
    {
        HTMLElement *link = [row firstNodeMatchingSelector:@"a"];
        
        NSString *title = [link.textContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        _episodeID = link[@"data-value"];
        
        _episodeDescription = title;
    }
    return self;
}

-(void)fetchStreamURLs:(void (^)())completion
{
    NSURL *url = [NSURL URLWithString:@"http://kisscartoon.me/Mobile/GetEpisode"];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"POST";
    req.HTTPBody = [[NSString stringWithFormat:@"eID=%@", _episodeID] dataUsingEncoding:NSUTF8StringEncoding];
    //[req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    [NSURLConnection sendAsynchronousKissAnimeRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        HTMLDocument *document = [HTMLDocument documentWithString:text];
        
        [self setStreamURLsFromDetailPage:document];
        
        if (completion)
            dispatch_async(dispatch_get_main_queue(), completion);
    }];
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

-(void)setStreamURLsFromDetailPage:(HTMLDocument *)document
{
    NSArray *links = [document nodesMatchingSelector:@"a"];
    NSMutableArray *qualities = [NSMutableArray new];
    NSMutableArray *streams = [NSMutableArray new];
    
    for (HTMLElement *link in links)
    {
        [qualities addObject:@([self _qualityForLinkText:[link textContent]])];
        [streams addObject:[NSURL URLWithString:link[@"href"]]];
    }
    
    [self _setVideoStreams:streams forQualities:qualities];
}

@end
