//
//  SeriesRequest.h
//  Anime
//
//  Created by David Quesada on 11/9/14.
//  Copyright (c) 2014 David Quesada. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SeriesGenre)
{
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

extern NSArray *allSeriesGenres();
extern NSArray *allSeriesGenreDescriptions();

extern NSString *seriesGenreDescription(SeriesGenre genre);


@interface SeriesRequest : NSObject

+(instancetype)recentSeriesRequest;
+(instancetype)searchSeriesRequestForQuery:(NSString *)query;
+(instancetype)popularSeriesRequest;
+(instancetype)ongoingSeriesRequest;
+(instancetype)seriesRequestForGenre:(SeriesGenre)genre;

@property(readonly) BOOL hasMoreAvailable;
@property(readonly,copy) NSArray *allSeries;

-(void)loadPageOfSeries:(void (^)(NSArray *nextPage))completion;

@end
