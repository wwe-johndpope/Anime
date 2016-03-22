//
//  KissAnimeSeriesRequest.m
//  Anime
//
//  Created by David Quesada on 5/7/15.
//  Copyright (c) 2015 David Quesada. All rights reserved.
//

#import "KissAnimeSeriesRequest.h"
#import "KissAnimeSeries_Private.h"
#import "HTMLReader.h"

@interface KissAnimeSeriesRequest ()
{
    BOOL _isLoadingFirstPage;
    BOOL _hasMoreAvailable;
    NSArray *_allSeries;
}
@property(readonly) NSString *sortParam;
@property(readonly) NSString *keyParam;
-(instancetype)initWithSort:(NSString *)sort key:(NSString *)key;
-(NSURLRequest *)selectNetworkRequest;
-(NSURLRequest *)_firstPageNetworkRequest;
-(NSURLRequest *)_nextPageNetworkRequest;
-(NSInteger)_loadedSeriesCount;
-(NSString *)_paramString:(BOOL)includeID;
-(NSArray *)_seriesForResponseData:(NSData *)data;
@end

@implementation KissAnimeSeriesRequest

@synthesize allSeries = _allSeries;
@synthesize hasMoreAvailable = _hasMoreAvailable;

#pragma mark - Public methods

-(void)loadPageOfSeries:(void (^)(NSArray *))completion
{
    NSURLRequest *req = [self selectNetworkRequest];
    [NSURLConnection sendAsynchronousKissAnimeRequest:req queue:[NSOperationQueue new] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        _isLoadingFirstPage = NO;
        NSArray *hits = [self _seriesForResponseData:data];
        
        if (_allSeries)
            _allSeries = [_allSeries arrayByAddingObjectsFromArray:hits];
        else
            _allSeries = hits; // or hits.copy?
        
        if (completion)
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(hits);
            });
        
    }];
}

#pragma mark - Class methods

+(instancetype)recentSeriesRequest
{
    return [[self alloc] initWithSort:@"latestupdate" key:nil];
}

+(instancetype)searchSeriesRequestForQuery:(NSString *)query
{
    return [[self alloc] initWithSort:@"search" key:query];
}

+(instancetype)popularSeriesRequest
{
    return [[self alloc] initWithSort:@"popular" key:nil];
}

+(instancetype)ongoingSeriesRequest
{
    return [[self alloc] initWithSort:@"ongoing" key:nil];
}

+(instancetype)seriesRequestForGenre:(SeriesGenre)genre
{
    return [[self alloc] initWithSort:@"genre" key:seriesGenreDescription(genre)];
}

#pragma Private Implementation

-(instancetype)initWithSort:(NSString *)sort key:(NSString *)key
{
    if ((self = [super init]))
    {
        _hasMoreAvailable = YES;
        _sortParam = sort;
        
        _keyParam = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                          NULL,
                                                                                          (CFStringRef)key,
                                                                                          NULL,
                                                                                          (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                          kCFStringEncodingUTF8 );
        _isLoadingFirstPage = YES;
    }
    return self;
}

-(NSURLRequest *)selectNetworkRequest
{
    if (_isLoadingFirstPage)
        return [self _firstPageNetworkRequest];
    return [self _nextPageNetworkRequest];
}

-(NSURLRequest *)_firstPageNetworkRequest
{
    NSString *urlString = [NSString stringWithFormat:@"http://kissanime.to/M?%@", [self _paramString:NO]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"GET";
    
    return req;
}

-(NSURLRequest *)_nextPageNetworkRequest
{
    NSString *urlString = @"http://kissanime.to/Mobile/GetNextUpdateAnime";
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"POST";
    req.HTTPBody = [[self _paramString:YES] dataUsingEncoding:NSUTF8StringEncoding];
    
    return req;
}

-(NSString *)_paramString:(BOOL)includeID
{
    NSMutableString *params = [NSMutableString new];
    
    if (includeID)
        [params appendFormat:@"id=%d&", (int)[self _loadedSeriesCount]];
    
    if (_sortParam)
        [params appendFormat:@"sort=%@&", _sortParam];
    
    if (_keyParam)
        [params appendFormat:@"key=%@", _keyParam];
    
    return params;
}

-(NSArray *)_seriesForResponseData:(NSData *)data
{
    HTMLDocument *doc = [HTMLDocument documentWithString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
    NSMutableArray *series = [NSMutableArray new];
    
    for (HTMLElement *article in [doc nodesMatchingSelector:@"article"])
        [series addObject:[[KissAnimeSeries alloc] initWithArticleElement:article]];
    
    return [series copy];
}

-(NSInteger)_loadedSeriesCount
{
    return _allSeries.count;
}

@end
