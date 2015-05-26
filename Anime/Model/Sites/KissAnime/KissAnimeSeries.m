//
//  KissAnimeSeries.m
//  Anime
//
//  Created by David Quesada on 5/7/15.
//  Copyright (c) 2015 David Quesada. All rights reserved.
//

#import "KissAnimeSeries.h"
#import "KissAnimeEpisode.h"
#import "HTMLReader.h"

static NSString *descriptionForSeriesStatus(SeriesStatus s)
{
    if (s == SeriesStatusOther)
        return @"Other";
    if (s == SeriesStatusCompleted)
        return @"Completed";
    if (s == SeriesStatusOngoing)
        return @"Ongoing";
    return @"Invalid";
}

static SeriesStatus statusForStatusDescription(NSString *desc)
{
    if ([desc isEqualToString:@"Completed"])
        return SeriesStatusCompleted;
    if ([desc isEqualToString:@"Ongoing"])
        return SeriesStatusOngoing;
    return SeriesStatusOther;
}

@interface KissAnimeSeries ()
{
    NSString *_seriesTitle;
    NSString *_seriesDescription;
    NSString *_seriesID;
    NSURL    *_imageURL;
    NSString *_seriesStatusDescription;
    SeriesStatus _seriesStatus;
    NSArray *_episodes;
}
@property NSString *docpath;

-(void)setDataFromArticleElement:(HTMLElement *)article;
-(void)setDataFromSeriesPage:(HTMLDocument *)page includeInfo:(BOOL)info;
@end

@implementation KissAnimeSeries

@synthesize seriesTitle = _seriesTitle, seriesDescription = _seriesDescription, seriesID = _seriesID,
        imageURL = _imageURL, seriesStatus = _seriesStatus, seriesStatusDescription = _seriesStatusDescription,
        episodes = _episodes;

-(instancetype)initWithArticleElement:(HTMLElement *)article
{
    if ((self = [super init]))
        [self setDataFromArticleElement:article];
    return self;
}

-(void)setDataFromArticleElement:(HTMLElement *)article
{
    NSString *docpath = [article firstNodeMatchingSelector:@"a"].attributes[@"href"]; // ie. /M/Anime/One-Piece
    NSString *imgURL = [article firstNodeMatchingSelector:@"img"].attributes[@"src"];
    NSString *title = [article firstNodeMatchingSelector:@"h2 a"].textContent;
    //    NSString *curEpisode = [article firstNodeMatchingSelector:@"p"].textContent;
    
    HTMLElement *statusSpan = [article firstNodeMatchingSelector:@"span"];
    
    NSString *status = [statusSpan textContent];
    //    NSString *statusClass = statusSpan.attributes[@"class"]; // bggray ('Completed'), bggreen ('Ongoing'), bglight (idunno)
    SeriesStatus sstatus = statusForStatusDescription(status);
    
    _seriesTitle = title;
    _seriesDescription = nil; // Not available only given an article.
    _seriesID = [docpath substringFromIndex:9]; // Remove the '/M/Anime/'
    _docpath = docpath;
    _imageURL = [NSURL URLWithString:imgURL];
    _seriesStatusDescription = descriptionForSeriesStatus(sstatus);
    _seriesStatus = sstatus;
    
    _episodes = nil;
}

-(void)fetchEpisodes:(void (^)())completion
{
    NSString *_url = [NSString stringWithFormat:@"http://kissanime.com%@", _docpath];
    NSURL *url = [NSURL URLWithString:_url];
    
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    
    [NSURLConnection sendAsynchronousKissAnimeRequest:req queue:[NSOperationQueue new] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        NSString *str = [NSString stringWithContentsOfURL:url usedEncoding:nil error:nil];
        HTMLDocument *doc = [HTMLDocument documentWithString:str];
        [self setDataFromSeriesPage:doc includeInfo:NO];
        
        if (completion)
            dispatch_async(dispatch_get_main_queue(), completion);
        
    }];
}

-(void)setDataFromSeriesPage:(HTMLDocument *)doc includeInfo:(BOOL)info
{
    HTMLNode *contentNode = [doc firstNodeMatchingSelector:@".content"];
    
    if (info)
    {
        id article = [contentNode firstNodeMatchingSelector:@"article"];
        [self setDataFromArticleElement:article];
    }
    
    //    NSString *genres = [[[contentNode nodesMatchingSelector:@"div"][3] firstNodeMatchingSelector:@"p"] textContent];
    NSString *description = [[[contentNode childElementNodes][6] firstNodeMatchingSelector:@"p"] textContent];
    
    NSMutableArray *episodes = [NSMutableArray new];
    
    // var wra = asp.wrap("base64encodedstuffbBus889fjJL9+jflsk+etcetera"); \n document.write(wra)
    NSString *encodedContentScript = [[contentNode nodesMatchingSelector:@"script"][2] textContent];
    encodedContentScript = [encodedContentScript substringFromIndex:1+[encodedContentScript rangeOfString:@"\""].location];
    encodedContentScript = [encodedContentScript substringToIndex:[encodedContentScript rangeOfString:@"\""].location];
    
    NSData *episodeListData = [[NSData alloc] initWithBase64EncodedString:encodedContentScript options:0];
    NSString *episodeListContent = [[NSString alloc] initWithData:episodeListData encoding:NSUTF8StringEncoding];
    
    id episodeList = [HTMLDocument documentWithString:episodeListContent];
    
    for (HTMLElement *ep in [episodeList nodesMatchingSelector:@".episode"])
    {
        NSString *episodeID = ep.attributes[@"data-value"];
        NSString *episodeDesc = ep.textContent;
        id ep = [[KissAnimeEpisode alloc] initWithID:episodeID description:episodeDesc];
        
        [episodes addObject:ep];
    }
    
    _seriesDescription = description;
    // Reverse the array so that the episodes are in forward chronological order.
    _episodes = episodes.reverseObjectEnumerator.allObjects;
}

+(void)fetchSeriesWithID:(NSString *)seriesID completion:(void (^)(Series *))completion
{
    NSString *_url = [NSString stringWithFormat:@"http://kissanime.com/M/Anime/%@", seriesID];
    NSURL *url = [NSURL URLWithString:_url];
    [NSURLConnection sendAsynchronousKissAnimeRequest:[NSURLRequest requestWithURL:url] queue:[NSOperationQueue new] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        id doc = [HTMLDocument documentWithString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
        
        KissAnimeSeries *s = [[KissAnimeSeries alloc] init];
        [s setDataFromSeriesPage:doc includeInfo:YES];
        
        if (completion)
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completion(s);
            }];
    }];
}

+(NSString *)siteIdentifier
{
    return @"kissanime.mobile";
}

@end
