//
//  RecentViewController.m
//  Anime
//
//  Created by David Quesada on 11/9/14.
//  Copyright (c) 2014 David Quesada. All rights reserved.
//

#import "RecentViewController.h"
#import "Recents.h"
#import "Episode.h"
#import "Series.h"
#import "SeriesViewController.h"
#import "PlayerViewController.h"

@import AVFoundation;
@import AVKit;
@import CoreMedia;


@implementation UITableView(THING)
-(BOOL)touchesShouldCancelInContentView:(UIView *)view
{
    return YES;
}
@end



@class RecentTableViewCell;
@protocol RecentTableViewCellDelegate
@optional
-(void)recentTableViewCellDidClickInfoButton:(RecentTableViewCell *)cell;
@end

@interface RecentTableViewCell : UITableViewCell
{
@public
    IBOutlet UIImageView *thumbnailImageView;
    IBOutlet UILabel *titleLabel;
    IBOutlet UILabel *episodeLabel;
}
@property(weak) id<RecentTableViewCellDelegate> delegate;
@end

@implementation RecentTableViewCell

-(IBAction)buttonPressed:(id)sender
{
    if ([(NSObject *)self.delegate respondsToSelector:@selector(recentTableViewCellDidClickInfoButton:)])
        [self.delegate recentTableViewCellDidClickInfoButton:self];
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    if (highlighted)
        self.contentView.alpha = 0.75f;
    else
        self.contentView.alpha = 1.0f;
}

@end


@interface RecentViewController ()<UISearchControllerDelegate, RecentTableViewCellDelegate>
{
    UISearchController *cont;
}
@end

@implementation RecentViewController

-(IBAction)search:(id)sender
{
    [self.navigationController pushViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"search"] animated:YES];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
//    self.navigationController.navigationBar.barTintColor = [UIColor colorWithWhite:0.0 alpha:0.0];
//    self.navigationController.navigationBar.barTintColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    
    
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
//    UIView *v = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    
//    v.frame = CGRectMake(0, -20, 160, 64.0);
    v.frame = CGRectMake(0, 0, self.view.frame.size.width, 64.0 );
    
    v.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
//    v.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:1.0];
    v.backgroundColor = [UIColor blackColor];
//    v.backgroundColor = [UIColor redColor];
    v.alpha = 0.60;
    UIView *bar = self.navigationController.navigationBar;
    
//    [self.navigationController.view insertSubview:v belowSubview:bar];
    
    bar = (id)bar.subviews[0];
    [bar insertSubview:v atIndex:0];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:nil style:UIBarButtonItemStyleDone target:nil action:nil];
    
    self.tableView.delaysContentTouches = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thumbnailChanged:) name:ThumbnailDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(watchesChanged:) name:RecentsWasChangedNotification object:nil];
}

-(void)continueWatching:(RecentWatch *)watch
{
    id c = [[PlayerViewController alloc] initWithWatch:watch];
    self.modalPresentationCapturesStatusBarAppearance = YES;
    [self presentViewController:c animated:YES completion:^{
//        self.tableView.contentOffset = CGPointZero;
        
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }];
    
    return;
}

-(void)showDetailViewController:(UIViewController *)vc sender:(id)sender
{
    if ([vc isKindOfClass:[SeriesViewController class]])
    {
        if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        {
            [self.navigationController pushViewController:vc animated:YES];
            return;
        }
    }
    
    [super showDetailViewController:vc sender:sender];
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(showDetailViewController:sender:))
    {
        if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        {
            return NO;
        }
    }
    return [super canPerformAction:action withSender:sender];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showSeries"])
    {
        // We need to grab a Series object and populate the destination view controller.
        SeriesViewController *dest = segue.destinationViewController;
        
        if ([sender isKindOfClass:[Series class]])
        {
            dest.series = sender;
        } else if ([sender isKindOfClass:[UIControl class]])
        {
            while (sender && ![sender isKindOfClass:[UITableViewCell class]])
                sender = [sender superview];
            NSAssert(sender, @"Sender was not a subview of a UITableViewCell.");
            NSIndexPath *ip = [self.tableView indexPathForCell:sender];
            RecentWatch *w = [[Recents defaultRecentStore] watches][ip.row];
            
            [Series fetchSeriesWithID:w.seriesID completion:^(Series *series) {
                dest.series = series;
            }];
        }
    }
}

#pragma mark - Notifications

-(void)thumbnailChanged:(NSNotification *)note
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        NSCAssert(![[Recents defaultRecentStore] watches].count || self.tableView.indexPathsForVisibleRows, @"Apparently this happens. There are no visible rows when there should be. The view is probably not in the view hierarchy.");
        
        [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationNone];
    }];
}

-(void)watchesChanged:(NSNotification *)note
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
    }];
}

#pragma mark - RecentTableViewCellDelegate

-(void)recentTableViewCellDidClickInfoButton:(RecentTableViewCell *)cell
{return;
    NSIndexPath *ipath = [self.tableView indexPathForCell:cell];
    RecentWatch *watch = [[Recents defaultRecentStore] watches][ipath.row];
    
    NSLog(@"%@", watch.seriesTitle);
    
    [Series fetchSeriesWithID:watch.seriesID completion:^(Series *series) {
        
        SeriesViewController *ser = [self.storyboard instantiateViewControllerWithIdentifier:@"seriesViewController"];
        ser.series = series;
        
#warning Refactor this logic.
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            [self.navigationController pushViewController:ser animated:YES];
        else
        {
            ser.modalPresentationStyle = UIModalPresentationFormSheet;
            self.modalPresentationCapturesStatusBarAppearance = YES;
            [self presentViewController:ser animated:YES completion:nil];
        }
        
    }];
}

-(UIViewController *)childViewControllerForStatusBarHidden
{
    UIViewController *c = self.presentedViewController;
    if ([c isKindOfClass:[PlayerViewController class]])
        return nil;
    return c;
}

#pragma mark - UITableView

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RecentWatch *w = [[Recents defaultRecentStore] watches][indexPath.row];
    RecentTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"YO"];
    
    cell.delegate = self;
    
//    UIImageView *imageView = (id)[cell viewWithTag:177];
//    UILabel *seriesLabel = (id)[cell viewWithTag:1000];
//    UILabel *epLabel = (id)[cell viewWithTag:2000];
    
    UIImageView *imageView = cell->thumbnailImageView;
    UILabel *seriesLabel = cell->titleLabel;
    UILabel *epLabel = cell->episodeLabel;

    if (w.cachedThumbnail)
        imageView.image = w.cachedThumbnail;
    else
    {
        imageView.image = nil;
        [w fetchThumbnailWithCompletion:^{
            
            // Check, so we don't keep infinitely reloading this row if we're unable to load the thumbnail.
            if (w.cachedThumbnail)
                [self.tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationNone];
        }];
    }
    
    seriesLabel.text = w.seriesTitle;
    epLabel.text = w.episodeTitle;
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RecentWatch *w = [[Recents defaultRecentStore] watches][indexPath.row];
    
    UIImage *img = w.cachedThumbnail;
    
    if (!img)
        return 180;
    
    return img.size.height * tableView.frame.size.width / img.size.width;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[Recents defaultRecentStore] watches].count;
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    RecentWatch *w = [[Recents defaultRecentStore] watches][indexPath.row];
    [[Recents defaultRecentStore] removeWatch:w];
    
    [tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RecentWatch *w = [[Recents defaultRecentStore] watches][indexPath.row];
    [self continueWatching:w];
}

@end
