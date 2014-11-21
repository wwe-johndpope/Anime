//
//  SeriesRequest.m
//  Anime
//
//  Created by David Quesada on 11/9/14.
//  Copyright (c) 2014 David Quesada. All rights reserved.
//

#import "SeriesRequest.h"
#import "Series.h"
#import "HTMLReader.h"

NSArray *allSeriesGenres()
{
    static NSArray *arr = nil;
    
    if (!arr)
    {
        SeriesGenre rawTypes[] = {
    SeriesGenreAction,
    SeriesGenreAdventure,
    SeriesGenreCars,
    SeriesGenreCartoon,
    SeriesGenreComedy,
    SeriesGenreDementia,
    SeriesGenreDemons,
    SeriesGenreDrama,
    SeriesGenreDub,
    SeriesGenreEcchi,
    SeriesGenreFantasy,
    SeriesGenreGame,
    SeriesGenreHarem,
    SeriesGenreHistorical,
    SeriesGenreHorror,
    SeriesGenreJosei,
    SeriesGenreKids,
    SeriesGenreMagic,
    SeriesGenreMartialArts,
    SeriesGenreMecha,
    SeriesGenreMilitary,
    SeriesGenreMovie,
    SeriesGenreMusic,
    SeriesGenreMystery,
    SeriesGenreONA,
    SeriesGenreOVA,
    SeriesGenreParody,
    SeriesGenrePolice,
    SeriesGenrePsychological,
    SeriesGenreRomance,
    SeriesGenreSamurai,
    SeriesGenreSchool,
    SeriesGenreSciFi,
    SeriesGenreSeinen,
    SeriesGenreShoujo,
    SeriesGenreShoujoAi,
    SeriesGenreShounen,
    SeriesGenreShounenAi,
    SeriesGenreSliceOfLife,
    SeriesGenreSpace,
    SeriesGenreSpecial,
    SeriesGenreSports,
    SeriesGenreSuperPower,
    SeriesGenreSupernatural,
    SeriesGenreThriller,
    SeriesGenreVampire,
    SeriesGenreYuri,
        };
        NSMutableArray *vals = [NSMutableArray new];
        for (int i = 0; i < (sizeof(rawTypes) / sizeof(rawTypes[0])); i++)
            [vals addObject:@(rawTypes[i])];
        arr = [vals copy];
    }
    return arr;
};

NSString *seriesGenreDescription(SeriesGenre genre)
{
#define GENRE(val,desc) case val: return desc; break
    switch (genre) {
        GENRE(SeriesGenreAction, @"Action");
        GENRE(SeriesGenreAdventure, @"Adventure");
        GENRE(SeriesGenreCars, @"Cars");
        GENRE(SeriesGenreCartoon, @"Cartoon");
        GENRE(SeriesGenreComedy, @"Comedy");
        GENRE(SeriesGenreDementia, @"Dementia");
        GENRE(SeriesGenreDemons, @"Demons");
        GENRE(SeriesGenreDrama, @"Drama");
        GENRE(SeriesGenreDub, @"Dub");
        GENRE(SeriesGenreEcchi, @"Ecchi");
        GENRE(SeriesGenreFantasy, @"Fantasy");
        GENRE(SeriesGenreGame, @"Game");
        GENRE(SeriesGenreHarem, @"Harem");
        GENRE(SeriesGenreHistorical, @"Historical");
        GENRE(SeriesGenreHorror, @"Horror");
        GENRE(SeriesGenreJosei, @"Josei");
        GENRE(SeriesGenreKids, @"Kids");
        GENRE(SeriesGenreMagic, @"Magic");
        GENRE(SeriesGenreMartialArts, @"Martial Arts");
        GENRE(SeriesGenreMecha, @"Mecha");
        GENRE(SeriesGenreMilitary, @"Military");
        GENRE(SeriesGenreMovie, @"Movie");
        GENRE(SeriesGenreMusic, @"Music");
        GENRE(SeriesGenreMystery, @"Mystery");
        GENRE(SeriesGenreONA, @"ONA");
        GENRE(SeriesGenreOVA, @"OVA");
        GENRE(SeriesGenreParody, @"Parody");
        GENRE(SeriesGenrePolice, @"Police");
        GENRE(SeriesGenrePsychological, @"Psychological");
        GENRE(SeriesGenreRomance, @"Romance");
        GENRE(SeriesGenreSamurai, @"Samurai");
        GENRE(SeriesGenreSchool, @"School");
        GENRE(SeriesGenreSciFi, @"SciFi");
        GENRE(SeriesGenreSeinen, @"Seinen");
        GENRE(SeriesGenreShoujo, @"Shoujo");
        GENRE(SeriesGenreShoujoAi, @"Shoujo Ai");
        GENRE(SeriesGenreShounen, @"Shounen");
        GENRE(SeriesGenreShounenAi, @"Shounen Ai");
        GENRE(SeriesGenreSliceOfLife, @"Slice of Life");
        GENRE(SeriesGenreSpace, @"Space");
        GENRE(SeriesGenreSpecial, @"Special");
        GENRE(SeriesGenreSports, @"Sports");
        GENRE(SeriesGenreSuperPower, @"Super Power");
        GENRE(SeriesGenreSupernatural, @"Supernatural");
        GENRE(SeriesGenreThriller, @"Thriller");
        GENRE(SeriesGenreVampire, @"Vampire");
        GENRE(SeriesGenreYuri, @"Yuri");
    }
#undef GENRE
    return nil;
}

@interface SeriesRequest ()
{
    BOOL _isLoadingFirstPage;
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

@implementation SeriesRequest

#pragma mark - Public methods

-(void)loadPageOfSeries:(void (^)(NSArray *))completion
{
    NSURLRequest *req = [self selectNetworkRequest];
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue new] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
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
    return [[SeriesRequest alloc] initWithSort:@"latestupdate" key:nil];
}

+(instancetype)searchSeriesRequestForQuery:(NSString *)query
{
    return [[SeriesRequest alloc] initWithSort:@"search" key:query];
}

+(instancetype)popularSeriesRequest
{
    return [[SeriesRequest alloc] initWithSort:@"popular" key:nil];
}

+(instancetype)ongoingSeriesRequest
{
    return [[SeriesRequest alloc] initWithSort:@"ongoing" key:nil];
}

+(instancetype)seriesRequestForGenre:(SeriesGenre)genre
{
    return [[SeriesRequest alloc] initWithSort:@"genre" key:seriesGenreDescription(genre)];
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
    NSString *urlString = [NSString stringWithFormat:@"http://kissanime.com/M?%@", [self _paramString:NO]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"GET";
    
    return req;
}

-(NSURLRequest *)_nextPageNetworkRequest
{
    NSString *urlString = @"http://kissanime.com/Mobile/GetNextUpdateAnime";
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
        [series addObject:[[Series alloc] initWithArticleElement:article]];
    
    return [series copy];
}

-(NSInteger)_loadedSeriesCount
{
    return _allSeries.count;
}

@end
