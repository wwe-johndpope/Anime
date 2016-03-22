//
//  KissCartoonSeries.m
//  Anime
//
//  Created by David Quesada on 5/26/15.
//  Copyright (c) 2015 David Quesada. All rights reserved.
//

#import "KissCartoonSeries.h"
#import "KissCartoonEpisode.h"
#import "HTMLReader.h"
#import "NSURLConnection+KissAnime.h"

static NSString *kKissCartoonSeriesPageFormat = @"http://kisscartoon.me/Cartoon/%@";

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
    if ([desc rangeOfString:@"Completed"].location != NSNotFound)
        return SeriesStatusCompleted;
    return SeriesStatusOngoing;
}

@interface KissCartoonSeries ()
{
    NSString *_seriesTitle;
    NSString *_seriesDescription;
    NSString *_seriesID;
    NSURL    *_imageURL;
    NSString *_seriesStatusDescription;
    SeriesStatus _seriesStatus;
    NSArray *_episodes;
}

-(void)setDataFromSearchResultsRow:(HTMLElement *)data;
-(void)setDataFromDetailPage:(HTMLDocument *)page;
-(void)setEpisodeDataFromListing:(HTMLElement *)table;

@end

@implementation KissCartoonSeries

@synthesize seriesTitle = _seriesTitle, seriesDescription = _seriesDescription, seriesID = _seriesID,
imageURL = _imageURL, seriesStatus = _seriesStatus, seriesStatusDescription = _seriesStatusDescription,
episodes = _episodes;

-(instancetype)initWithSeriesDiv:(HTMLElement *)data
{
    if ((self = [super init]))
        [self setDataFromSearchResultsRow:data];
    return self;
}

-(instancetype)initWithSeriesID:(NSString *)seriesID
{
    if ((self = [super init]))
        _seriesID = seriesID;
    return self;
}

-(instancetype)initWithDetailPage:(HTMLDocument *)page
{
    if ((self = [super init]))
    {
        [self setDataFromDetailPage:page];
        
        HTMLElement *episodeTable = [page firstNodeMatchingSelector:@".listing"];
        [self setEpisodeDataFromListing:episodeTable];
    }
    return self;
}

-(void)setDataFromSearchResultsRow:(HTMLElement *)data
{
    HTMLElement *a = [data firstNodeMatchingSelector:@"a"];
    
    HTMLElement *img = [a firstNodeMatchingSelector:@"img"];
    NSString *imgsrc = img[@"src"];
    if (imgsrc && imgsrc.length)
        _imageURL = [NSURL URLWithString:imgsrc];
    
    _seriesTitle = img.attributes[@"title"];
    _seriesID = [a[@"href"] substringFromIndex:9]; // example href: "/Cartoon/Futurama-Season-01"
}

-(void)setDataFromDetailPage:(HTMLDocument *)page
{
    HTMLElement *img = [page firstNodeMatchingSelector:@"img"];
    
    _seriesTitle = img[@"title"];
    _imageURL = [NSURL URLWithString:img[@"src"]];
}

-(void)setEpisodeDataFromListing:(HTMLElement *)ul
{
    NSArray *rows = [ul childElementNodes];
    
    NSEnumerator *ptr = [rows objectEnumerator];

    NSMutableArray *episodes = [NSMutableArray new];
    
    for (HTMLElement *listItem in ptr)
    {
        Episode *ep = [[KissCartoonEpisode alloc] initWithTableRow:listItem seriesTitle:self.seriesTitle];
        [episodes addObject:ep];
        
        // Every <li> containing episode title is followed by another with class "sub", where the player
        // is placed. It doesn't contain any info for us now, so we skip it.
        [ptr nextObject];
    }
    
    // Reverse to put them in chronological order.
    _episodes = episodes.reverseObjectEnumerator.allObjects;
}

-(void)fetchEpisodes:(void (^)())completion
{
    [self fetchEpisodes:completion otherStuffToo:NO];
}

-(void)fetchEpisodes:(void (^)())completion otherStuffToo:(BOOL)stuff
{
    if (_episodes.count)
    {
        if (completion)
            dispatch_async(dispatch_get_main_queue(), completion);
        return;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kKissCartoonSeriesPageFormat, self.seriesID]];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    
    [NSURLConnection sendAsynchronousKissAnimeRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        HTMLDocument *document = [HTMLDocument documentWithString:text];
        
        HTMLElement *episodeList = [document firstNodeMatchingSelector:@".list"];

        if (stuff)
            [self setDataFromDetailPage:document];
        
        [self setEpisodeDataFromListing:episodeList];
        
        if (completion)
            dispatch_async(dispatch_get_main_queue(), completion);
    }];
}

+(void)fetchSeriesWithID:(NSString *)seriesID completion:(void (^)(Series *))completion
{
    KissCartoonSeries *series = [[self alloc] initWithSeriesID:seriesID];
    
    [series fetchEpisodes:^{
        if (completion)
            completion(series);
    } otherStuffToo:YES];
}

+(NSString *)siteIdentifier
{
    return @"kisscartoon";
}

@end
