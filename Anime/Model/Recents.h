//
//  Recents.h
//  Anime
//
//  Created by David Quesada on 11/9/14.
//  Copyright (c) 2014 David Quesada. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Series, Episode, RecentWatch;


/*
 Posted when the thumbnail for a RecentWatch changed.
 Object - the RecentWatch object associated with the new thumbnail.
 UserInfo
    - ThumbnailSeriesKey - the Series object associated with the notification
    - ThumbnailImageKey - the UIImage of the new thumbnail.
 */
extern NSString * const ThumbnailDidChangeNotification;
extern NSString * const ThumbnailSeriesKey;
extern NSString * const ThumbnailImageKey;

extern NSString * const RecentsWasChangedNotification;


@interface Recents : NSObject

+(void)loadRecents;
+(instancetype)defaultRecentStore;

@property(readonly) NSArray *watches;

-(void)setActiveSeries:(Series *)series episode:(Episode *)episode;
-(void)setThumbnail:(UIImage *)image forSeries:(Series *)series;
-(void)setSeekTime:(NSTimeInterval)time;
-(void)clearWatchedSeries;

-(void)removeWatch:(RecentWatch *)watch;

@end

// A lightweight
@interface RecentWatch : NSObject

@property(readonly) NSString *seriesID;
@property(readonly) NSString *seriesTitle;
@property(readonly) NSString *episodeID;
@property(readonly) NSString *episodeTitle;
@property(readonly) NSTimeInterval seekTime;

@property(readonly) UIImage *cachedThumbnail;

-(void)fetchThumbnailWithCompletion:(void (^)())completion;

-(Episode *)makeEpisode;

@end
