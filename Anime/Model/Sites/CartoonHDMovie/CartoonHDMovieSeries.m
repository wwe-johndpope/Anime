//
//  CartoonHDMovieSeries.m
//  Anime
//
//  Created by David Quesada on 5/7/15.
//  Copyright (c) 2015 David Quesada. All rights reserved.
//

#import "CartoonHDMovieSeries.h"

@implementation CartoonHDMovieSeries

+(NSString *)siteIdentifier
{
    return @"cartoonhd.movie";
}

+(NSURL *)categoriesURL
{
    static NSURL *url = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        url = [NSURL URLWithString:@"http://gearscenter.com/cartoon_control/gapi-ios/index.php?op_select=catalog&os=ios&param_10=AIzaSyBsxsynyeeRczZJbxE8tZjnWl_3ALYmODs&param_7=1.0.0&param_8=com.gearsapp.cartoonhd&type_film=Movie"];
    });
    return url;
}

@end
