//
//  SearchViewController.m
//  Anime
//
//  Created by David Quesada on 11/10/14.
//  Copyright (c) 2014 David Quesada. All rights reserved.
//

#import "SearchViewController.h"
#import "Series.h"
#import "SeriesRequest.h"
#import "SeriesViewController.h"
#import "PlayerViewController.h"

@interface SearchViewController ()<UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource>
{
    BOOL hasAppeared;
    SeriesRequest *req;
    
    NSString *_seriesIDBeingLoaded;
    __weak SeriesViewController *_seriesViewController;
    
    Series *_seriesBeingLoaded;
    IBOutlet NSLayoutConstraint *_searchBarTopConstraint;
}
@property IBOutlet UISearchBar *bar;
@property IBOutlet UINavigationBar *navBar;

@property IBOutlet UITableView *tableView;

@end

@implementation SearchViewController

-(void)dealloc
{
    [[UIApplication sharedApplication] removeObserver:self forKeyPath:@"statusBarHidden"];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    _navBar.delegate = self;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:@{
                                                                                                     NSForegroundColorAttributeName:[UIColor whiteColor],
                                                                                                     NSFontAttributeName:[UIFont systemFontOfSize:14.0],
                                                                                                     }];
    });
    
    UISearchBar *bar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 500, 44)];
    bar.barStyle = UIBarStyleBlack;
    bar.barTintColor = [UIColor redColor];
    bar.showsCancelButton = NO;
    bar.delegate = self;
    bar.keyboardAppearance = UIKeyboardAppearanceDark;
    
    NSLayoutConstraint *c = nil;
    c = [NSLayoutConstraint constraintWithItem:self.navBar
                                 attribute:NSLayoutAttributeTop
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self.topLayoutGuide
                                 attribute:NSLayoutAttributeBottom
                                multiplier:1.0
                                  constant:0.0];
    c.identifier = @"SearchBarTop";
    [self.view addConstraint:c];
    
    self.navBar.topItem.titleView = bar;
    self.navBar.barStyle = UIBarStyleBlack;
    self.navBar.tintColor = self.navigationController.navigationBar.tintColor;
    
    self.navBar.topItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    
    self.bar = bar;
    
    [[UIApplication sharedApplication] addObserver:self forKeyPath:@"statusBarHidden" options:NSKeyValueObservingOptionNew context:nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!hasAppeared)
        [self.bar becomeFirstResponder];
    hasAppeared = YES;
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    
    if (self.tableView.indexPathForSelectedRow)
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
        [self.bar resignFirstResponder];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    SeriesViewController *c = segue.destinationViewController;
    [_seriesBeingLoaded fetchEpisodes:^{
        c.series = _seriesBeingLoaded;
    }];
}

-(UIViewController *)childViewControllerForStatusBarHidden
{
    UIViewController *c = self.presentedViewController;
    if ([c isKindOfClass:[PlayerViewController class]])
        return nil;
    return c;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"statusBarHidden"])
    {
        
    }
}

-(void)updateConstraintForStatusBarHidden:(BOOL)hidden
{
    
}

-(void)cancel:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

-(UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
//    if ([UIApplication sharedApplication].statusBarHidden)
//        return UIBarPositionTop;
    return UIBarPositionTopAttached;
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    
    req = [SeriesRequest searchSeriesRequestForQuery:searchBar.text];
    
    [req loadPageOfSeries:^(NSArray *nextPage) {
        [self.tableView reloadData];
    }];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"seriesCell"];
    
    Series *s = req.allSeries[indexPath.row];
    
    cell.textLabel.text = s.seriesTitle;
    cell.detailTextLabel.text = s.seriesStatusDescription;
    
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return req.allSeries.count;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Series *s = req.allSeries[indexPath.row];

    _seriesBeingLoaded = s;
    [self performSegueWithIdentifier:@"showSeries" sender:nil];
    
//
//    SeriesViewController *ser = [self.storyboard instantiateViewControllerWithIdentifier:@"seriesViewController"];
//    
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
//        [self.navigationController pushViewController:ser animated:YES];
//    else
//    {
//        //            UINavigationController *c = [[UINavigationController alloc] initWithRootViewController:ser];
//        //            c.modalPresentationStyle = UIModalPresentationFormSheet;
//        //            c.navigationBar.barStyle = UIBarStyleBlack;
//        //            [self presentViewController:c animated:YES completion:nil];
//        //ser.modalPresentationStyle = UIModalPresentationFormSheet;
//        [self presentViewController:ser animated:YES completion:nil];
//    }
//    
//    [s fetchEpisodes:^{
//        ser.series = s;
//    }];
}

@end
