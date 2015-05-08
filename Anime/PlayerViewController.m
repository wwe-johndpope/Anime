//
//  PlayerViewController.m
//  Anime
//
//  Created by David Quesada on 11/9/14.
//  Copyright (c) 2014 David Quesada. All rights reserved.
//

#import "PlayerViewController.h"
#import "AnimePlayer.h"
#import "Recents.h"
#import "Series.h"
#import "Episode.h"
@import AVFoundation;
@import ObjectiveC;

@interface AVPlayerViewController (PrivateAPI)

-(void)_showOrHidePlaybackControlsView;

@end


@interface PlayerViewController ()<AnimePlayerDelegate>
{
    Series *_series;
    Episode *_currentEpisode;
    
    UILabel *thing;
}
-(void)nextTrack;
@end

@implementation PlayerViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self makeThing];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    
    [self saveScreenshot];
    
    [[Recents defaultRecentStore] setSeekTime:(NSTimeInterval)CMTimeGetSeconds(self.player.currentTime)];
    [[Recents defaultRecentStore] clearWatchedSeries];
}

-(void)makeThing
{
    CGRect r = self.view.bounds;
    r.origin.y += 50;
    r = CGRectInset(r, 10, 0);
    r.size.height = 80;
    thing = [[UILabel alloc] initWithFrame:r];
    thing.font = [UIFont systemFontOfSize:20];
    thing.textColor = [UIColor whiteColor];
    thing.lineBreakMode = NSLineBreakByWordWrapping;
    
    //    thing.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    
    thing.layer.shadowColor = [UIColor blackColor].CGColor;
    thing.layer.shadowRadius = 2.5;
    thing.layer.shadowOpacity = 1.0;
    thing.layer.masksToBounds = NO;
    thing.layer.shadowOffset = CGSizeZero;
    
    thing.numberOfLines = 0;
    
    [self positionLabelForViewWidth:self.view.frame.size.width];
    [self.contentOverlayView addSubview:thing];
}

-(void)positionLabelForViewWidth:(CGFloat)width
{
    CGRect r = CGRectMake(0, 50, width, 1000);
    r = CGRectInset(r, 10, 10);
    thing.frame = r;
    [thing sizeToFit];
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self positionLabelForViewWidth:size.width];
    } completion:nil];
}

-(void)saveScreenshot
{
    AVAsset *asset = self.player.currentItem.asset;
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    CMTime time = self.player.currentTime;
    
    time = CMTimeMakeWithSeconds(MAX(0, CMTimeGetSeconds(time) - 0.5), 1);
    
    [imageGenerator generateCGImagesAsynchronouslyForTimes:@[ [NSValue valueWithCMTime:time] ] completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
        
        CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
        UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);  // CGImageRef won't be released by ARC
        
        NSLog(@"Setting new thumbnail.");
        [[Recents defaultRecentStore] setThumbnail:thumbnail forSeries:_series];
    }];
}

-(void)nextTrack
{
    [(AnimePlayer *)self.player advanceToNextItem];
}

-(instancetype)initWithSeries:(Series *)series episode:(Episode *)episode
{
    if ((self = [self init]))
    {
        _series = series;
        _currentEpisode = episode;
        
        [_series fetchEpisodes:^{
            self.player = [AnimePlayer playerWithSeries:series episode:episode];
            ((AnimePlayer *)self.player).delegate = self;
        }];
    }
    return self;
}

-(instancetype)initWithWatch:(RecentWatch *)watch
{
    if ((self = [self init]))
    {
        // Ugly.
        [Series fetchSeriesWithQualifiedID:watch.seriesID completion:^(Series *sr) {
            
            _series = sr;
            
            self.player = [AnimePlayer playerWithWatch:watch];
            ((AnimePlayer *)self.player).delegate = self;
        }];
    }
    return self;
}

-(void)updateHUD
{
    if (!_currentEpisode)
        thing.text = @"";
    else
        thing.text = [NSString stringWithFormat:@"%@\n%@", _series.seriesTitle, _currentEpisode.episodeDescription];
    [self positionLabelForViewWidth:self.view.frame.size.width];
}

-(void)_showOrHidePlaybackControlsView
{
    [super _showOrHidePlaybackControlsView];
    
    id val = [self valueForKey:@"_showsPlaybackControlsView"];
    BOOL s = [val boolValue];
    
    [UIView animateWithDuration:0.42 delay:0 usingSpringWithDamping:.9 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        thing.alpha = (CGFloat)!!s;
    } completion:nil];
}

-(void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    // TODO: How do we make it so we can tap the 'next' button on screen to do this as well?
    if (event.subtype == UIEventSubtypeRemoteControlNextTrack)
    {
        [(AnimePlayer *)self.player advanceToNextItem];
    } else if (event.subtype == UIEventSubtypeRemoteControlPlay)
    {
        [self.player play];
    }
    //    else if (event.subtype == UIEventSubtypeRemoteControlPause)
    //        [self.player pause]
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
}

#pragma mark - AnimePlayerDelegate

-(void)animePlayerDidPlay:(AnimePlayer *)player
{
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

-(void)animePlayerDidPause:(AnimePlayer *)player
{
    //[self updateHUD];
    
    NSTimeInterval time = CMTimeGetSeconds(player.currentTime);
    
    NSLog(@"%dm %ds", (int)(time / 60), (int)time % 60);
    
    [[Recents defaultRecentStore] setSeekTime:time];
}

-(void)animePlayerDidFinishPlayback:(AnimePlayer *)player
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)animePlayer:(AnimePlayer *)player didChangeItem:(EpisodePlayerItem *)item
{
    if (item)
    {
        _currentEpisode = item.episode;
        
        [[Recents defaultRecentStore] setActiveSeries:_series episode:item.episode];
        [player play];
        
        [self updateHUD];
        
        if (item.playbackQuality == StreamQualityUnknown)
            NSLog(@"Playing at unknown quality.");
        if (item.playbackQuality == StreamQuality240)
            NSLog(@"Playing at 240p quality.");
        if (item.playbackQuality == StreamQuality360)
            NSLog(@"Playing at 360p quality.");
        if (item.playbackQuality == StreamQuality720)
            NSLog(@"Playing at 720p quality.");
        if (item.playbackQuality == StreamQuality1080)
            NSLog(@"Playing at 1080p quality.");
    }
}

@end

#pragma mark - Swizzling

IMP ORIGINAL_SFBTUI; // see +[AVKitHacks load]

void NEW_SFBTUI(NSObject *self, SEL cmd, id sender)
{
    // It seems occasionally, after tapping the button, the player thinks the user is still holding
    // down the button, and playback runs fast until the button is tracked over again. Perhaps calling
    // the original method will resolve this issue.
    
    void (*fn)(NSObject *, SEL, id) = (void (*)(NSObject *, SEL, id))ORIGINAL_SFBTUI;
    fn(self, cmd, sender);
    
    NSString *key = @"_plaH!yerVH!iewCH!ontrH!olleH!r";
    key = [key stringByReplacingOccurrencesOfString:@"H!" withString:@""];
    
    PlayerViewController *c = [self valueForKey:key];
    [c nextTrack];
}

@interface AVKitHacks : NSObject
@end

@implementation AVKitHacks

+(void)load
{
    // Obfuscate our references to private API.
    
    // Class AVFullScreenPlaybackControlsViewController
    // Method _scanForwardButtonTouchUpInside:
    
    NSString *class_name = [@"AVFW.ullSW.creeW.nPlaW.ybacW.kConW.trolW.sVieW.wConW.trolW.ler" stringByReplacingOccurrencesOfString:@"W." withString:@""];
    NSString *method_name = [@"_scaW.nForW.wardW.ButtW.onToW.uchUW.pInsW.ide:" stringByReplacingOccurrencesOfString:@"W." withString:@""];
    
    Class cl = NSClassFromString(class_name);
    SEL sel = NSSelectorFromString(method_name);
    IMP newimp = (IMP)NEW_SFBTUI;
    
    if (cl)
        ORIGINAL_SFBTUI = class_replaceMethod(cl, sel, newimp, "@");
    else
        NSLog(@"Class AVFullScreenPlaybackControlsViewController doesn't exist. Not swizzling.");
}

@end
