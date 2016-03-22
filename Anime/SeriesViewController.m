//
//  SeriesViewController.m
//  Anime
//
//  Created by David Quesada on 11/9/14.
//  Copyright (c) 2014 David Quesada. All rights reserved.
//

#import "SeriesViewController.h"
#import "HTMLReader.h"
#import "PlayerViewController.h"
#import "Episode.h"
#import "Series.h"
#import "Recents.h"

@interface SeriesViewController ()<UIGestureRecognizerDelegate, UIActionSheetDelegate>
{
    Series *_series;
    BOOL _needReloadSeriesOnViewDidLoad;
    UIActivityIndicatorView *_activityIndicatorView;
    
    IBOutlet NSLayoutConstraint *imageHeightConstraint;
    IBOutlet NSLayoutConstraint *textHeightConstraint;
    
    BOOL _alternateSort;
    
    BOOL _floatsHeader;
    BOOL _installsGesture;
    
    // There's some weirdness going on with iPad. If the table view is scrolled down, then the header
    // view isn't visible when animating the presentation/dismissal of the player view. So we use a
    // snapshot so the table view looks correct when doing the animation.
    BOOL _usesSnapshotView;
    
    UIView *sectionHeader;
    UIView *_snapshotView;
    
    UITapGestureRecognizer *_tapGesture;
    UILongPressGestureRecognizer *_longPressGesture;
    
    Episode *_actionSheetEpisode;
}

@property IBOutlet UIImageView *posterImageView;
@property IBOutlet UILabel *titleLabel;
@property IBOutlet UILabel *statusLabel;
@property IBOutlet UILabel *descriptionLabel;
@property IBOutlet UITextView *descriptionTextView;

@property IBOutletCollection(UIView) NSArray *episodeControls;

@end

@implementation SeriesViewController

+(void)load
{
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setTextColor:[UIColor whiteColor]];
    
    [[UIView appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setBackgroundColor:[UIColor blackColor]];
}

-(void)dealloc
{
    if (_tapGesture.view)
        [_tapGesture.view removeGestureRecognizer:_tapGesture];
}

-(void)viewDidLoad {
    
    [super viewDidLoad];
    
    _descriptionTextView.scrollsToTop = NO;
    
    
    _descriptionTextView.text = nil;
    _statusLabel.text = nil;
    _titleLabel.text = nil;
    [_episodeControls setValue:@(0.0) forKey:@"alpha"];
    self.navigationItem.title = nil;
    
    self.tableView.tableHeaderView.backgroundColor = [UIColor clearColor];
    [self resizeHeaderView];
    
    BOOL isiPad = (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad);
    _installsGesture = _floatsHeader = isiPad;
    _usesSnapshotView = isiPad;
    
    if (_floatsHeader)
    {
//        self.tableView.tableHeaderView.userInteractionEnabled = YES;
        sectionHeader = self.tableView.tableHeaderView;
        self.tableView.tableHeaderView = nil;
    }
    
    UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.tableView.backgroundView = view;
    [view startAnimating];
    _activityIndicatorView = view;
    
    if (_needReloadSeriesOnViewDidLoad)
    {
        self.series = self.series;
        _needReloadSeriesOnViewDidLoad = NO;
    }
    
    _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.tableView addGestureRecognizer:_longPressGesture];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

-(void)thing:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        // Keep us from getting "stuck" if we're showing the quality UIAlertViewController.
        // (Otherwise, when the user taps the shade not covered by this view or the popover,
        // the popover is dismissed and the gesture is uninstalled.)
        if (self.presentedViewController != nil)
            return;
        
        // If we're not in the view hierarchy (e.g. we've presented the movie player),
        // the tap gesture should not do anything. Ideally we should be smarter and disable
        // the gesture when we know it shouldn't be there.
        if (!self.view.window)
            return;
        
        CGPoint location = [sender locationInView:nil];
        if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
        {
            location = CGPointMake(location.y, location.x);
        }
        
        // if tap outside pincode inputscreen
        BOOL inView = [self.view pointInside:[self.view convertPoint:location     fromView:self.view.window] withEvent:nil];
        if (!inView)
        {
            [_tapGesture.view removeGestureRecognizer:_tapGesture];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (_floatsHeader)
    {
        CGRect r = self.tableView.tableHeaderView.bounds;
        r.origin = CGPointZero;
        
        r.origin.y = scrollView.contentOffset.y + self.topLayoutGuide.length;
        r.origin.y = MAX(0, r.origin.y);
        UIView *view;
//        view = self.tableView.tableHeaderView.subviews.firstObject;
        view = sectionHeader;
//        view = self.tableView.tableHeaderView;
//        view.frame = r;
        
        CGFloat y = self.tableView.contentOffset.y + self.topLayoutGuide.length;
        
        if (y < 0)
        {
            self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(view.frame.size.height + self.topLayoutGuide.length - y, 0, 0, 0);
        } else
            self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(view.frame.size.height + self.topLayoutGuide.length, 0, 0, 0);
    }
}

-(void)loadPoster:(id)_
{
    NSData *data = [NSData dataWithContentsOfURL:self.series.imageURL];
    UIImage *image = [UIImage imageWithData:data];
    [self performSelectorOnMainThread:@selector(setPosterImage:) withObject:image waitUntilDone:NO];
}

-(void)setPosterImage:(UIImage *)image
{
    if (!image)
    {
        NSLog(@"Nil poster image.");
        return;
    }
    
    self.posterImageView.image = image;
    CGFloat ratio = image.size.height / image.size.width;
    CGFloat height = self.posterImageView.frame.size.width * ratio;
    imageHeightConstraint.constant = height;
    
    
    CGRect rect = CGRectZero;
    rect.size.width = self.posterImageView.frame.size.width;
    rect.size.height = height;
    
    rect.origin.x = self.posterImageView.frame.origin.x - self.descriptionTextView.frame.origin.x;
    rect.origin.y = self.posterImageView.frame.origin.y - self.descriptionTextView.frame.origin.y;
    
    rect.size.height -= 4;
    rect.size.width += 6;
    UIBezierPath *ex = [UIBezierPath bezierPathWithRect:rect];
    
    self.descriptionTextView.textContainer.exclusionPaths = @[ ex ];
    [self.descriptionTextView sizeToFit];
    
    [self resizeHeaderView];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self resizeHeaderView];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (_installsGesture && !_tapGesture)
    {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(thing:)];
        _tapGesture.delegate = self;
        _tapGesture.cancelsTouchesInView = NO;
        [self.view.window addGestureRecognizer:_tapGesture];
    }
    
    if (_snapshotView)
    {
        [UIView animateWithDuration:.25 animations:^{
            _snapshotView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [_snapshotView removeFromSuperview];
        }];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (_usesSnapshotView)
    {
        _snapshotView = [self.view snapshotViewAfterScreenUpdates:YES];
        
        CGRect r = self.view.frame;
        r.origin = CGPointZero;
        
        r.origin.y += self.tableView.contentOffset.y;
        
        _snapshotView.frame = r;
        
        self.view.clipsToBounds = YES;
        [self.view addSubview:_snapshotView];
    }
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [self resizeHeaderView];
}


-(void)resizeHeaderAsSectionHeaderView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UIView *header = sectionHeader;
        
        [header layoutIfNeeded];
        
        textHeightConstraint.constant = self.descriptionTextView.contentSize.height;
        
        // Layout AGAIN, since we changed the height of the textview.
        [header layoutIfNeeded];
        
        [self.tableView beginUpdates];
        
        header.frame = [header.subviews[0] bounds];
        
        [self.tableView endUpdates];
        
        if (_floatsHeader)
        {
            self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(header.frame.size.height + self.topLayoutGuide.length, 0, 0, 0);
        }
    });
}

-(void)resizeHeaderView
{
    if (_floatsHeader)
        [self resizeHeaderAsSectionHeaderView];
    else
        [self resizeHeaderAsTableHeaderView];
}

-(void)resizeHeaderAsTableHeaderView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UIView *header = self.tableView.tableHeaderView;

        [header layoutIfNeeded];
        
//        textHeightConstraint.constant = self.descriptionTextView.contentSize.height;
        
//        [self.descriptionTextView sizeToFit];
        textHeightConstraint.constant = self.descriptionTextView.contentSize.height;
        
        // Layout AGAIN, since we changed the height of the textview.
        [header layoutIfNeeded];
        
        header.frame = [header.subviews[0] bounds];
        header.frame = [header.subviews[0] bounds];
        
        self.tableView.tableHeaderView = header;
        
        if (_floatsHeader)
        {
            self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(header.frame.size.height + self.topLayoutGuide.length, 0, 0, 0);
        }
    });
}

-(IBAction)changeEpisodeSort:(id)sender
{
    _alternateSort = !_alternateSort;
    [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationMiddle];
}

-(Episode *)_episodeAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger idx = [indexPath row];
    if (_alternateSort)
        idx = (self.series.episodes.count - 1 - idx);
    return self.series.episodes[idx];
}

-(Series *)series
{
    return _series;
}

-(void)longPress:(UILongPressGestureRecognizer *)sender
{
    if (sender.state != UIGestureRecognizerStateBegan)
        return;
    
    CGPoint point = [sender locationInView:self.tableView];
    NSIndexPath *idx = [self.tableView indexPathForRowAtPoint:point];
    
    // Ignore cells under the header view.
    if (CGRectContainsPoint(sectionHeader.frame, point))
        return;
    
    Episode *ep = [self _episodeAtIndexPath:idx];
    [ep fetchStreamURLs:^{
        _actionSheetEpisode = ep;
        
        UIActionSheet *sheet = [[UIActionSheet alloc] init];
        sheet.title = ep.episodeDescription;
        
        for (NSNumber *quality in ep.allStreamQualities)
            [sheet addButtonWithTitle:StreamQualityDescription((StreamQuality)quality.integerValue)];
        
        [sheet setCancelButtonIndex:[sheet addButtonWithTitle:@"Cancel"]];
        sheet.delegate = self;
        
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:idx];
        CGRect rect;
        rect.size = CGSizeMake(1, 1);
        rect.origin = [sender locationInView:cell];
        [sheet showFromRect:rect inView:cell animated:YES];
    }];
}

-(void)setSeries:(Series *)series
{
    _series = series;
    
    if (!self.isViewLoaded)
    {
        _needReloadSeriesOnViewDidLoad = YES;
        return;
    }
    
    [self performSelectorInBackground:@selector(loadPoster:) withObject:nil];
    
    self.titleLabel.text = self.series.seriesTitle;
    self.statusLabel.text = self.series.seriesStatusDescription;
    self.descriptionLabel.text = self.series.seriesDescription;
    
    self.descriptionTextView.text = self.series.seriesDescription;
    // For some reason, changes to this in IB don't take effect; the text stays black.
    self.descriptionTextView.textColor = [UIColor lightGrayColor];
    
    _activityIndicatorView.hidden = YES;
    [_episodeControls setValue:@(1.0) forKey:@"alpha"];
    
    self.navigationItem.title = self.series.seriesTitle;
    
    if (self.isViewLoaded)
    {
        [self.tableView reloadData];
    }
}

// Use StreamQualityUnknown to play at the user-selected default quality.
-(void)showEpisode:(Episode *)ep withQuality:(StreamQuality)quality
{
    PlayerViewController *player = [[PlayerViewController alloc] initWithSeries:self.series episode:ep];

    player.preferredStreamQuality = quality;
    
    //    self.modalPresentationCapturesStatusBarAppearance = YES;
    [self presentViewController:player animated:YES completion:^{
        //        [self.tableView scrollRectToVisible:CGRectMake(0, 0, .5, .5) animated:NO];
        //        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        //        [UIApplication sharedApplication].statusBarHidden = YES;
    }];
    
}

#pragma mark - UIActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex)
        return;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        StreamQuality q = (StreamQuality)[_actionSheetEpisode.allStreamQualities[buttonIndex] integerValue];
        [self showEpisode:_actionSheetEpisode withQuality:q];
        _actionSheetEpisode = nil;
    }];
}

#pragma mark - UITableViewDataSource / Delegate

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:@"WTF"];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"WTF"];
    
    Episode *ep = [self _episodeAtIndexPath:indexPath];
    cell.textLabel.text = ep.episodeDescription;
    return cell;
}

//-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
//{
//    return 32.0f;
//}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.5;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.series.episodes.count;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Episode *ep = [self _episodeAtIndexPath:indexPath];
    [self showEpisode:ep withQuality:StreamQualityUnknown];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    static UIColor *c = nil;
    if (!c)
        c = [UIColor colorWithWhite:.1 alpha:1.0];
    [cell setBackgroundColor:c];
    [cell.textLabel setTextColor:[UIColor whiteColor]];
}

-(void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.textLabel.textColor = [UIColor blackColor];
}

-(void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.textLabel.textColor = [UIColor whiteColor];
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!_floatsHeader)
        return indexPath;
    
    CGRect r = [tableView rectForRowAtIndexPath:indexPath];
    CGFloat y = r.origin.y + r.size.height - tableView.contentOffset.y;
    y -= self.topLayoutGuide.length;
    if (y < self.tableView.tableHeaderView.frame.size.height)
        return nil;
    return indexPath;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return sectionHeader.frame.size.height;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (_floatsHeader)
        return sectionHeader;
    return nil;
}

@end
