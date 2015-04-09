//
//  NSURLConnection+KissAnime.h
//  Anime
//
//  Created by David Quesada on 4/7/15.
//  Copyright (c) 2015 David Quesada. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLConnection (KissAnime)

+(void)sendAsynchronousKissAnimeRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue completionHandler:(void (^)(NSURLResponse *, NSData *, NSError *))handler;

@end
