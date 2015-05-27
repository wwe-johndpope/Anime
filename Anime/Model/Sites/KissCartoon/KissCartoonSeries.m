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
#import "HTMLTextNode.h"

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
-(void)setEpisodeDataFromListingTable:(HTMLElement *)table;

@end

@implementation KissCartoonSeries

@synthesize seriesTitle = _seriesTitle, seriesDescription = _seriesDescription, seriesID = _seriesID,
imageURL = _imageURL, seriesStatus = _seriesStatus, seriesStatusDescription = _seriesStatusDescription,
episodes = _episodes;

-(instancetype)initWithSeriesTR:(HTMLElement *)data
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
        [self setEpisodeDataFromListingTable:episodeTable];
    }
    return self;
}

-(void)setDataFromSearchResultsRow:(HTMLElement *)data
{
    NSArray *tableCells = [data childElementNodes];
    
    // td0 - Poster Image, Title, ID, Summary
    // td1 - "Completed" iff the series is completed
    
    HTMLElement *td0, *td1;
    td0 = tableCells[0];
    td1 = tableCells[1];
    
    _seriesStatus = statusForStatusDescription(td1.textContent);
    _seriesStatusDescription = descriptionForSeriesStatus(_seriesStatus);
    
    HTMLDocument *info = [HTMLDocument documentWithString:td0[@"title"]];
    
    // Yikes!
    NSArray *infoChildren = [[[[[info children] lastObject] children] lastObject] childElementNodes];
    
    NSString *img = infoChildren[0][@"src"];
    if (img && img.length)
        _imageURL = [NSURL URLWithString:img];
    
    HTMLElement *div = infoChildren[1];
    NSArray *divChildren = [div childElementNodes];
    HTMLElement *link = divChildren[0];
    HTMLElement *summary = divChildren[1];
    
    _seriesTitle = link.textContent;
    _seriesID = [link[@"href"] substringFromIndex:9]; // example href: "/Cartoon/Futurama-Season-01"
    _seriesDescription = [summary.textContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(void)setDataFromDetailPage:(HTMLDocument *)page
{
    HTMLElement *box = [page firstNodeMatchingSelector:@".bigBarContainer"];
    HTMLElement *boxContent = [box firstNodeMatchingSelector:@".barContent"];
    boxContent = boxContent.childElementNodes.lastObject;
    NSArray *content = boxContent.childElementNodes;
    
    NSString *seriesURL = [boxContent firstNodeMatchingSelector:@"a"][@"href"];
    NSRange cartoonRange = [seriesURL rangeOfString:@"/Cartoon/"];
    _seriesID = [seriesURL substringFromIndex:cartoonRange.location + 9];
    
    _seriesTitle = [[box firstNodeMatchingSelector:@"a"] textContent];
    _seriesDescription = [[content[content.count - 2] textContent] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    HTMLElement *rightside = [page firstNodeMatchingSelector:@"#rightside"];
    NSString *url = [rightside firstNodeMatchingSelector:@"img"][@"src"];
    if (url && url.length)
        _imageURL = [NSURL URLWithString:url];
    
    // Convoluted method of determining the series status.
    if (content.count >= 4)
    {
        HTMLElement *p = content[3];
        NSEnumerator *ptr = p.children.objectEnumerator;
        
        for (HTMLNode *node in ptr)
        {
            HTMLElement *span = (HTMLElement *)node;
            
            if (![span isKindOfClass:[HTMLElement class]])
                continue;
            if (![span.tagName isEqualToString:@"span"])
                continue;
            
            if ([span.textContent isEqualToString:@"Status:"])
            {
                HTMLTextNode *node = [ptr nextObject];
                
                // Not what we're looking for. Abort!
                if (![node isKindOfClass:[HTMLTextNode class]])
                    break;
                
                NSString *text = node.data;
                if ([text rangeOfString:@"Completed"].location != NSNotFound)
                    _seriesStatus = SeriesStatusCompleted;
                else if ([text rangeOfString:@"Ongoing"].location != NSNotFound)
                    _seriesStatus = SeriesStatusOngoing;
                
                if (_seriesStatus != SeriesStatusOther)
                    _seriesStatusDescription = descriptionForSeriesStatus(_seriesStatus);
                
                break;
            }
        }
    }
}

-(void)setEpisodeDataFromListingTable:(HTMLElement *)table
{
    NSArray *rows = [table childElementNodes];
    
    // The HTMLReader library seems to add a tbody element to tables.
    if (rows.count == 1 && [[[rows lastObject] tagName] isEqualToString:@"tbody"])
        rows = [[rows lastObject] childElementNodes];
    
    NSEnumerator *ptr = [rows objectEnumerator];
    
    // The first two rows are a header and a spacer.
    [ptr nextObject];
    [ptr nextObject];

    NSMutableArray *episodes = [NSMutableArray new];
    
    for (HTMLElement *tableRow in ptr)
    {
        Episode *ep = [[KissCartoonEpisode alloc] initWithTableRow:tableRow seriesTitle:self.seriesTitle];
        [episodes addObject:ep];
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
    
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        HTMLDocument *document = [HTMLDocument documentWithString:text];
        
        HTMLElement *episodeTable = [document firstNodeMatchingSelector:@".listing"];
        
        // Do this before the episode list, since that might depend on the series title.
        if (stuff)
            [self setDataFromDetailPage:document];
        
        [self setEpisodeDataFromListingTable:episodeTable];
        
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
