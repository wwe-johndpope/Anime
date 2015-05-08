//
//  CartoonHDSeriesRequest.m
//  Anime
//
//  Created by David Quesada on 4/9/15.
//  Copyright (c) 2015 David Quesada. All rights reserved.
//

#import "CartoonHDSeriesRequest.h"
#import "CartoonHDSeries.h"

@interface CartoonHDSeriesRequest ()
{
    NSArray *_allSeries;
}
@property NSURL *requestURL;
@property NSString *searchTerm;

-(instancetype)initWithURL:(NSURL *)url;

@end

@implementation CartoonHDSeriesRequest

// Why is this necessary in a subclass?
@synthesize allSeries = _allSeries;

#pragma mark - Private Implementation

-(instancetype)initWithURL:(NSURL *)url
{
    if ((self = [super init]))
        self.requestURL = url;
    return self;
}

#pragma mark - Public Methods

+(instancetype)popularSeriesRequest { return nil; }
+(instancetype)ongoingSeriesRequest { return nil; }
+(instancetype)seriesRequestForGenre:(SeriesGenre)genre { return nil; }

+(instancetype)recentSeriesRequest
{
    return nil;
}
+(instancetype)searchSeriesRequestForQuery:(NSString *)query
{
    NSString * AnimationURL = @"http://gearscenter.com/cartoon_control/gapi-ios/index.php?op_select=catalog&os=ios&param_10=AIzaSyBsxsynyeeRczZJbxE8tZjnWl_3ALYmODs&param_7=1.0.0&param_8=com.gearsapp.cartoonhd&type_film=Animation";
    CartoonHDSeriesRequest *req = [[self alloc] initWithURL:[NSURL URLWithString:AnimationURL]];
    req.searchTerm = query;
    return req;
}

-(BOOL)hasMoreAvailable
{
    return NO;
}

-(void)loadPageOfSeries:(void (^)(NSArray *nextPage))completion
{
    NSURLRequest *req = [NSURLRequest requestWithURL:self.requestURL];
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        if (connectionError || ((NSHTTPURLResponse *)response).statusCode != 200) {
            if (completion)
                completion(nil);
            return;
        }
        
        NSDictionary *r = [NSJSONSerialization JSONObjectWithData:data options:0 error:0];
        NSArray *arr = r[@"categories"];
        
        NSMutableArray *results = [NSMutableArray new];
        
        for (NSDictionary *cat in arr)
        {
            CartoonHDSeries *series = [[CartoonHDSeries alloc] initWithJSON:cat];
            
            if ([series.seriesTitle.lowercaseString rangeOfString:self.searchTerm.lowercaseString].location != NSNotFound)
                [results addObject:series];
        }
        
        _allSeries = results.copy;
        
        if (completion)
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(_allSeries);
            });
    }];
}

@end
