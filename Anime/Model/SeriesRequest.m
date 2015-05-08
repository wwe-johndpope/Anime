//
//  SeriesRequest.m
//  Anime
//
//  Created by David Quesada on 11/9/14.
//  Copyright (c) 2014 David Quesada. All rights reserved.
//

#import "SeriesRequest.h"

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

@implementation SeriesRequest

+(instancetype)recentSeriesRequest { return nil; }
+(instancetype)searchSeriesRequestForQuery:(NSString *)query { return nil; }
+(instancetype)popularSeriesRequest { return nil; }
+(instancetype)ongoingSeriesRequest { return nil; }
+(instancetype)seriesRequestForGenre:(SeriesGenre)genre { return nil; }

-(void)loadPageOfSeries:(void (^)(NSArray *nextPage))completion { }

@end

