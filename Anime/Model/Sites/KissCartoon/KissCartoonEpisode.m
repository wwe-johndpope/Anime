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

@interface KissCartoonEpisode ()
{
    NSString *_episodeID, *_episodeDescription;
    NSURL *_detailURL;
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
        NSString *url = link[@"href"];
        
        _detailURL = [NSURL URLWithString:url relativeToURL:[NSURL URLWithString:@"http://kisscartoon.me"]];
        
        NSRange idRange = [url rangeOfString:@"/" options:NSBackwardsSearch];
        idRange.location++;
        idRange.length--;
        
        // There seems to be something like ?id=12345 appended to the end of the
        // link, but it seems that's not necessary to load the page.
        NSRange qRange = [url rangeOfString:@"?" options:NSBackwardsSearch];
        if (qRange.location != NSNotFound)
            idRange.length = qRange.location - idRange.location - 1;
        
        _episodeID = [url substringWithRange:idRange];
        
        // The link texts all seem to have the title of the series prepended, e.g.
        // "Futurama Season 01 Episode 001 - Space Pilot 3000". Let's try to remove that.
        
        // If we were given a series title, let's dumbly remove the same length of
        // characters, plus one for the space.
        if (seriesTitle)
            title = [title substringFromIndex:(seriesTitle.length + 1)];
        
        // Otherwise, dumbly by taking the substring starting with "Episode." At the time of
        // writing this comment, "Robot Chicken Star Wars Episode {II,III}" are
        // the only series on KissCartoon whose titles have the word "Episode",
        // so I'm going to call that good enough for most cases.
        else
        {
            NSRange epRange = [title rangeOfString:@"Episode"];
            if (epRange.location != NSNotFound)
                title = [title substringFromIndex:epRange.location];
        }
        
        _episodeDescription = title;
    }
    return self;
}

-(void)fetchStreamURLs:(void (^)())completion
{
    NSURLRequest *req = [NSURLRequest requestWithURL:_detailURL];
    
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        HTMLDocument *document = [HTMLDocument documentWithString:text];
        
        [self setStreamURLsFromDetailPage:document];
        
        if (completion)
            dispatch_async(dispatch_get_main_queue(), completion);
    }];
}

-(void)setStreamURLsFromDetailPage:(HTMLDocument *)document
{
    HTMLElement *select = [document firstNodeMatchingSelector:@"#selectQuality"];
    NSMutableArray *qualities = [NSMutableArray new];
    NSMutableArray *streams = [NSMutableArray new];
    
    for (HTMLElement *option in select.childElementNodes)
    {
        NSInteger size = option.textContent.integerValue;
        NSString *value = option[@"value"]; // base64 encoded URL
        
        NSData *urlData = [[NSData alloc] initWithBase64EncodedString:value options:0];
        value = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
        
        [qualities addObject:@([self.class _qualityForVideoHeight:size])];
        [streams addObject:[NSURL URLWithString:value]];
    }
    
    [self _setVideoStreams:streams forQualities:qualities];
}

@end
