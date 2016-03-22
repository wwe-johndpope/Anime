//
//  NSURLConnection+KissAnime.m
//  Anime
//
//  Created by David Quesada on 4/7/15.
//  Copyright (c) 2015 David Quesada. All rights reserved.
//

#import "NSURLConnection+KissAnime.h"
#import "HTMLReader.h"

@import JavaScriptCore;

@implementation NSURLConnection (KissAnime)

+(void)load
{
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
}

+(void)sendAsynchronousKissAnimeRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue completionHandler:(void (^)(NSURLResponse *, NSData *, NSError *))handler
{
    [self sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        NSHTTPURLResponse *r = (NSHTTPURLResponse *)response;
        
        if (r.statusCode == 503)
            [self _redirectKissAnimeRequest:request onQueue:queue withChallengePageData:data completionHandler:handler];
        else if (handler)
            handler(response, data, connectionError);
    }];
}

+(void)_redirectKissAnimeRequest:(NSURLRequest *)request onQueue:(NSOperationQueue *)queue withChallengePageData:(NSData *)data completionHandler:(void (^)(NSURLResponse *, NSData *, NSError *))handler
{
    NSString *page = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    HTMLDocument *doc = [HTMLDocument documentWithString:page];
    HTMLNode *form = [doc firstNodeMatchingSelector:@"#challenge-form"];
    NSString *root_url = [self _baseURLForURL:request.URL];
    
    NSString *jscode = nil;
    
    for (HTMLNode *node in [doc nodesMatchingSelector:@"script"]) {
        NSString *code = node.textContent;
        if ([code rangeOfString:@"challenge-form" options:0 range:NSMakeRange(0, MIN(code.length, 1000))].location == NSNotFound)
            continue;
        
        jscode = code;
        break;
    }
    
    // Minimally emulate browser features the CloudFlare challenge script needs.
    NSString *prefix =
    @"this.document = {};\n\
    this.document.attachEvent = function(evt, fn) { fn(); };\n\
    this.document.getElementById = function(id) { a = elems[id]; a=a?a:{}; a.style={}; a.submit=function(){}; elems[id]=a; return a; };\n\
    this.setTimeout = function(fn, tm) { return fn(); };\n\
    this.document.createElement = function(tag) { return { \"firstChild\": { \"href\": root_url}};};\n\
    \n\
    ";
    
    JSContext *ctx = [[JSContext alloc] initWithVirtualMachine:[JSVirtualMachine new]];
    
    ctx[@"elems"] = [JSValue valueWithObject:@{} inContext:ctx];
    ctx[@"root_url"] = [JSValue valueWithObject:root_url inContext:ctx];
    
    [ctx evaluateScript:prefix];
    [ctx evaluateScript:jscode];
    
    NSString *jschl_answer = [ctx[@"elems"][@"jschl-answer"][@"value"] toString];
    NSString *jschl_vc, *pass;
    
    for (HTMLElement *input in [form nodesMatchingSelector:@"input"])
    {
        if ([input[@"name"] isEqualToString:@"jschl_vc"])
            jschl_vc = input[@"value"];
        else if ([input[@"name"] isEqualToString:@"pass"])
            pass = input[@"value"];
    }
    
    NSString *redirectURL = [NSString stringWithFormat:@"%@cdn-cgi/l/chk_jschl?jschl_vc=%@&pass=%@&jschl_answer=%@", root_url, jschl_vc, pass, jschl_answer];
    NSMutableURLRequest *newReq = [request mutableCopy];
    newReq.URL = [NSURL URLWithString:redirectURL];
    [newReq setValue:request.URL.description forHTTPHeaderField:@"Referer"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self sendAsynchronousRequest:newReq queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            if (handler)
                handler(response, data, connectionError);
        }];
    });
}

+(NSString *)_baseURLForURL:(NSURL *)url
{
    return [NSString stringWithFormat:@"%@://%@/", url.scheme, url.host];
}

@end
