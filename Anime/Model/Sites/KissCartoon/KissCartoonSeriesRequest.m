//
//  KissCartoonSeriesRequest.m
//  Anime
//
//  Created by David Quesada on 5/26/15.
//  Copyright (c) 2015 David Quesada. All rights reserved.
//

#import "KissCartoonSeriesRequest.h"
#import "HTMLReader.h"
#import "KissCartoonSeries.h"
#import "NSURLConnection+KissAnime.h"

static NSString * const kKissCartoonSearchURL = @"http://kisscartoon.me/Search/Cartoon";
static NSString * const kKissCartoonSearchRelativeURL = @"/Search/Cartoon";

@interface KissCartoonSeriesRequest ()
{
    NSArray *_allSeries;
}

@property NSURLRequest *firstPageRequest;

+(instancetype)seriesRequestWithKissCartoonRequest:(NSURLRequest *)networkRequest;

@end

@implementation KissCartoonSeriesRequest

#pragma mark - Private Implementation

+(instancetype)seriesRequestWithKissCartoonRequest:(NSURLRequest *)networkRequest
{
    KissCartoonSeriesRequest *req = [[self alloc] init];
    req.firstPageRequest = networkRequest;
    return req;
}

+(NSArray *)seriesListForResultsDocument:(HTMLDocument *)document
{
    HTMLElement *listing = [document firstNodeMatchingSelector:@".item-list"];
    NSArray *seriesDivs = [listing childElementNodes];
    NSMutableArray *list = [NSMutableArray new];
    
    for (HTMLElement *seriesDiv in seriesDivs)
    {
        Series *series = [[KissCartoonSeries alloc] initWithSeriesDiv:seriesDiv];
        [list addObject:series];
    }
    
    return list;
}

#pragma mark - Public Methods

+(instancetype)searchSeriesRequestForQuery:(NSString *)query
{
    query = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                  NULL,
                                                                                  (CFStringRef)query,
                                                                                  NULL,
                                                                                  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                  kCFStringEncodingUTF8 );
    
    NSLog(@"KissCartoon encoded search query: %@", query);
    
    NSString *body = [NSString stringWithFormat:@"keyword=%@", query];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:kKissCartoonSearchURL]];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    request.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];
    
    return [self seriesRequestWithKissCartoonRequest:request];
}

-(void)loadPageOfSeries:(void (^)(NSArray *))completion
{
    NSAssert(self.firstPageRequest, @"KissCartoonSeriesRequest must have an NSURLRequest object when being queried.");
    
    [NSURLConnection sendAsynchronousKissAnimeRequest:self.firstPageRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        HTMLDocument *document = [HTMLDocument documentWithString:text];
        
        NSArray *seriesList;
        
        if ([response.URL.relativePath isEqualToString:kKissCartoonSearchRelativeURL])
            seriesList = [self.class seriesListForResultsDocument:document];
        else if ([response.URL.relativePath hasPrefix:@"/Cartoon/"])
            seriesList = @[
                           [[KissCartoonSeries alloc] initWithDetailPage:document]
                           ];
        
        if (_allSeries)
            _allSeries = [_allSeries arrayByAddingObjectsFromArray:seriesList];
        else
            _allSeries = [seriesList copy];
        
        if (completion)
            completion(seriesList);
    }];
}

-(NSArray *)allSeries
{
    return _allSeries;
}

@end
