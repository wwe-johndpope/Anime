//
//  Site.m
//  Anime
//
//  Created by David Quesada on 4/9/15.
//  Copyright (c) 2015 David Quesada. All rights reserved.
//

#import "Site.h"

@implementation Site

+(NSString *)qualifiedIDForSeriesID:(NSString *)seriesID inSite:(NSString *)site
{
    return [NSString stringWithFormat:@"%@@@%@", seriesID, site];
}

+(NSString *)siteForQualifiedSeriesID:(NSString *)qualifiedSeriesID
{
    if ([qualifiedSeriesID rangeOfString:@"@@"].location == NSNotFound)
        return nil;
    return [qualifiedSeriesID componentsSeparatedByString:@"@@"][1];
}

+(NSString *)seriesIDForQualifiedSeriesID:(NSString *)qualifiedSeriesID
{
    if ([qualifiedSeriesID rangeOfString:@"@@"].location == NSNotFound)
        return qualifiedSeriesID;
    return [qualifiedSeriesID componentsSeparatedByString:@"@@"][0];
}

@end
