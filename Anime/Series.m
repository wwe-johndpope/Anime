//
//  Series.m
//  Anime
//
//  Created by David Quesada on 11/9/14.
//  Copyright (c) 2014 David Quesada. All rights reserved.
//

#import "Series.h"
#import "Episode.h"
#import "Site.h"
#import "Model/Sites/CartoonHD/CartoonHDSeries.h"
#import "Model/Sites/CartoonHDMovie/CartoonHDMovieSeries.h"
#import "Model/Sites/KissAnime/KissAnimeSeries.h"

@implementation Series

#pragma mark - Stubs: To be overridden in subclasses

+(void)fetchSeriesWithID:(NSString *)seriesID completion:(void (^)(Series *series))completion { }
-(void)fetchEpisodes:(void (^)())completion { }

+(NSString *)siteIdentifier { return nil; }

#pragma mark - Class methods

+(NSArray *)seriesLookupClasses
{
    return @[
             [CartoonHDSeries class],
             [KissAnimeSeries class],
             [CartoonHDMovieSeries class],
             ];
}

+(void)fetchSeriesWithQualifiedID:(NSString *)seriesID completion:(void (^)(Series *))completion
{
    NSString *site = [Site siteForQualifiedSeriesID:seriesID];
    NSString *sID = [Site seriesIDForQualifiedSeriesID:seriesID];
    
    Class seriesClass = Nil;
    
    if (site)
    {
        for (Class candidateClass in [self seriesLookupClasses])
        {
            if ([[candidateClass siteIdentifier] isEqualToString:site])
            {
                seriesClass = candidateClass;
                break;
            }
        }
    }
    else
        seriesClass = self;
    
    NSAssert(seriesClass != nil, @"Unable to find suitable series class to handle quailified series ID: %@", seriesID);
    
    [seriesClass fetchSeriesWithID:sID completion:completion];
}

#pragma mark - Default implementations.

#if TARGET_OS_IPHONE
-(void)fetchImage:(void (^)(BOOL, NSError *))completion
{
    if (!completion)
        completion = ^(BOOL s, NSError *e){ };
    
    if (_seriesImage)
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            completion(YES, nil);
        }];
        return;
    }
    
    NSURLRequest *req = [[NSURLRequest alloc] initWithURL:self.imageURL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:7.0];
    [NSURLConnection sendAsynchronousKissAnimeRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        if (!data)
        {
            completion(NO, connectionError);
            return;
        }
        
        UIImage *img = [UIImage imageWithData:data];
        
        if (!img)
        {
            completion(NO, nil);
            return;
        }
        
        _seriesImage = img;
        completion(YES, nil);
    }];
}
#endif

-(NSString *)qualifiedSeriesID
{
    NSString *series = self.seriesID;
    NSString *site = [self.class siteIdentifier];
    
    if (!site.length)
        return series;
    
    return [Site qualifiedIDForSeriesID:series inSite:site];
}

@end
