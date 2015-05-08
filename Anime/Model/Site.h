//
//  Site.h
//  Anime
//
//  Created by David Quesada on 4/9/15.
//  Copyright (c) 2015 David Quesada. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Site : NSObject

+(NSString *)qualifiedIDForSeriesID:(NSString *)seriesID inSite:(NSString *)site;
+(NSString *)siteForQualifiedSeriesID:(NSString *)qualifiedSeriesID;
+(NSString *)seriesIDForQualifiedSeriesID:(NSString *)qualifiedSeriesID;

@end
