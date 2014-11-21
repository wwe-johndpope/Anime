//
//  Episode.h
//  Anime
//
//  Created by David Quesada on 11/9/14.
//  Copyright (c) 2014 David Quesada. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, StreamQuality)
{
    StreamQualityUnknown = 0,
    
    // AKA 180
    StreamQuality240 = 1,
    
    // AKA 480
    StreamQuality360 = 2,
    StreamQuality720 = 4,
    StreamQuality1080 = 8,
    
    StreamQualityMaxAvailable = StreamQuality1080,
    StreamQualityMinUsed = StreamQuality240,
};

@interface Episode : NSObject

-(instancetype)initWithID:(NSString *)eID description:(NSString *)eDesc;

@property(readonly) NSString *episodeID;
@property(readonly) NSString *episodeDescription;


#pragma mark - Stream URL Management

-(void)fetchVideoURLs:(void (^)(NSArray *urls))completion;
-(void)fetchStreamURLs:(void (^)())completion;

@property(readonly) NSArray *allStreamQualities;
@property(readonly) NSArray *allStreamURLs;

-(NSURL *)streamURLForVideoQuality:(StreamQuality)quality;
-(NSURL *)streamURLOfMaximumQuality:(StreamQuality)quality;
-(NSURL *)streamURLOfMaximumQuality:(StreamQuality)quality
                      actualQuality:(StreamQuality *)actualQuality;

@property(readonly) NSURL *highestQualityStream;

@end
