//
//  CartoonHDSeries.m
//  Anime
//
//  Created by David Quesada on 4/9/15.
//  Copyright (c) 2015 David Quesada. All rights reserved.
//

#import "CartoonHDSeries.h"
#import "CartoonHDEpisode.h"

@interface CartoonHDSeries()
{
    NSString *_seriesTitle;
    NSString *_seriesDescription;
    NSString *_seriesID;
    NSString *_docpath;
    NSURL *_imageURL;
    
    NSArray *_episodes;
}

@end

@implementation CartoonHDSeries

@synthesize seriesTitle=_seriesTitle, seriesDescription=_seriesDescription, seriesID = _seriesID, docpath=_docpath, imageURL=_imageURL, episodes=_episodes;

-(instancetype)initWithJSON:(NSDictionary *)json
{
    if ((self = [super init]))
        [self _loadMainJSON:json];
    
    return self;
}

-(void)_loadMainJSON:(NSDictionary *)json
{
    _seriesTitle = json[@"catalog_name"];
    _seriesID = json[@"catalog_id"];
    
    // On Cartoon HD, this actually points to a landscape image.
    _imageURL = [NSURL URLWithString:json[@"catalog_icon"]];
}

-(void)_loadDetailJSON:(NSDictionary *)json
{
    _seriesDescription = json[@"catalog_desc"];
    _imageURL = [NSURL URLWithString:json[@"catalog_icon"]];
    
    NSMutableArray *eps = [NSMutableArray new];
    
    for (NSDictionary *data in json[@"films"])
    {
        CartoonHDEpisode *ep = [[CartoonHDEpisode alloc] initWithJSON:data];
        [eps addObject:ep];
    }
    
    // Reverse the array so that the episodes are in forward chronological order.
    _episodes = eps.reverseObjectEnumerator.allObjects;
}

-(void)fetchEpisodes:(void (^)())completion
{
    NSString *urlFormat = @"http://gearscenter.com/cartoon_control/gapi-ios/index.php?id_select=%@&op_select=films&os=ios&param_10=AIzaSyBsxsynyeeRczZJbxE8tZjnWl_3ALYmODs&param_7=1.0.0&param_8=com.gearsapp.cartoonhd";
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:urlFormat, self.seriesID]];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        NSDictionary *j = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        [self _loadDetailJSON:j];
        
        if (completion)
            completion();
    }];
}

// This is a really inefficient way of doing this.
// On the KissAnime site, we could just load the detail view, which gives us everything.
// On Cartoon HD, loading the detail page doesn't give us the title of the series, so we
// stupidly load the entire catalog to find the series with the matching ID.
+(void)fetchSeriesWithID:(NSString *)seriesID completion:(void (^)(Series *))completion
{
    NSURL *url = [NSURL URLWithString:@"http://gearscenter.com/cartoon_control/gapi-ios/index.php?op_select=catalog&os=ios&param_10=AIzaSyBsxsynyeeRczZJbxE8tZjnWl_3ALYmODs&param_7=1.0.0&param_8=com.gearsapp.cartoonhd&type_film=Animation"];
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url] queue:[NSOperationQueue new] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSArray *categories = json[@"categories"];
        
        for (NSDictionary *dict in categories)
        {
            if ([dict[@"catalog_id"] isEqualToString:seriesID])
            {
                CartoonHDSeries *series = [[self alloc] initWithJSON:dict];
                [series fetchEpisodes:^{
                    if (completion)
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(series);
                        });
                }];
                break;
            }
        }
    }];
}

+(NSString *)siteIdentifier
{
    return @"cartoonhd.animation";
}

@end
