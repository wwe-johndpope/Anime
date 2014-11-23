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
@import MediaPlayer;
@import AVFoundation;

//#define SHOW_SEL _showPlaybackControlsViewIfNeeded
//#define HIDE_SEL _hidePlaybackControlsViewIfPossible

#define SHOW_SEL showPlaybackControlsViewForTouchDown
#define HIDE_SEL hidePlaybackControlsViewForTouchUp

@interface AVPlayerViewController (PrivateAPI)
-(void)SHOW_SEL;
-(void)HIDE_SEL;

-(void)_showOrHidePlaybackControlsView;
- (double)transitionDuration:(id)arg1;

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
        Episode *ep = [watch makeEpisode];
        
        // Ugly.
        [Series fetchSeriesWithID:watch.seriesID completion:^(Series *sr) {
           
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
    
    //[self updateHUD];
    
//    [UIView animateWithDuration:0.35 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
//            thing.alpha = (CGFloat)!!s;
//    } completion:nil];
    
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
    
    // We need to use PlayAndRecord so we can set the override to use the 'speaker' port.
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    [self setForceHeadphonesAudio:[self hasHeadphones]];
}

-(void)setForceHeadphonesAudio:(BOOL)force
{
    NSError *error = nil;
    AVAudioSessionPortOverride override = force ? AVAudioSessionPortOverrideSpeaker : AVAudioSessionPortOverrideNone;
    if (![[AVAudioSession sharedInstance] overrideOutputAudioPort:override error:&error])
        NSLog(@"overrideOutputAudioPort error: %@", error);
}

-(BOOL)hasHeadphones
{
    AVAudioSessionRouteDescription *route = [[AVAudioSession sharedInstance] currentRoute];
    
    for (AVAudioSessionPortDescription *output in route.outputs)
    {
        if ([output.portType isEqualToString:AVAudioSessionPortHeadphones])
            return YES;
    }
    return NO;
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

#pragma mark - HAXX!

@interface AVFullScreenPlaybackControlsViewController : UIViewController
@end

@implementation AVFullScreenPlaybackControlsViewController (DERP)

-(void)_scanForwardButtonTouchUpInside:(id)sender
{
#warning We might need to call the super for this method.
    // It seems occasionally, after tapping the button, the player thinks the user is still holding
    // down the button, and playback runs fast until the button is tracked over again. Perhaps calling
    // the original method will resolve this issue.
    
//    [super _scanForwardButtonTouchUpInside:sender];
    PlayerViewController *c = [self valueForKey:@"_playerViewController"];
    [c nextTrack];
}

@end

