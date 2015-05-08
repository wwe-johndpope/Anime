//
//  Series.h
//  Anime
//
//  Created by David Quesada on 11/9/14.
//  Copyright (c) 2014 David Quesada. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SeriesStatus)
{
    SeriesStatusOther,
    SeriesStatusCompleted,
    SeriesStatusOngoing,
};



@class HTMLElement;
@class HTMLDocument;

@interface Series : NSObject

+(void)fetchSeriesWithID:(NSString *)seriesID completion:(void (^)(Series *series))completion;
+(void)fetchSeriesWithQualifiedID:(NSString *)seriesID completion:(void (^)(Series *series))completion;

@property(readonly) NSString *seriesTitle;
@property(readonly) NSString *seriesDescription;
@property(readonly) NSString *seriesID; // e.g. Hunter-X-Hunter-2011
@property(readonly) NSString *docpath;
@property(readonly) NSURL *imageURL;

@property(readonly) NSString *seriesStatusDescription;
@property(readonly) SeriesStatus seriesStatus;

@property(readonly) NSArray *episodes;

-(instancetype)initWithArticleElement:(HTMLElement *)elem;
-(instancetype)initWithSeriesDocument:(HTMLDocument *)doc;

-(void)fetchEpisodes:(void (^)())completion;

// Image loading

#if TARGET_OS_IPHONE
@property(readonly) UIImage *seriesImage;
-(void)fetchImage:(void (^)(BOOL success, NSError *error))completion;
#endif

@property(readonly) NSString *qualifiedSeriesID;
+(NSString *)siteIdentifier;

@end
