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
}
@property IBOutlet UISearchBar *bar;
@property IBOutlet UINavigationBar *navBar;

@property IBOutlet UITableView *tableView;

@end

@implementation SearchViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    _navBar.delegate = self;
    
    UISearchBar *bar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 500, 44)];
    bar.barStyle = UIBarStyleBlack;
    bar.barTintColor = [UIColor redColor];
    bar.showsCancelButton = NO;
    bar.delegate = self;
    bar.keyboardAppearance = UIKeyboardAppearanceDark;
    
    self.navBar.topItem.titleView = bar;
    self.navBar.barStyle = UIBarStyleBlack;
    self.navBar.tintColor = self.navigationController.navigationBar.tintColor;
    
    self.navBar.topItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    
    self.bar = bar;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!hasAppeared)
        [self.bar becomeFirstResponder];
    hasAppeared = YES;
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
        [self.bar resignFirstResponder];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

-(UIViewController *)childViewControllerForStatusBarHidden
{
    UIViewController *c = self.presentedViewController;
    if ([c isKindOfClass:[PlayerViewController class]])
        return nil;
    return c;
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Series *s = req.allSeries[indexPath.row];

    
    SeriesViewController *ser = [self.storyboard instantiateViewControllerWithIdentifier:@"seriesViewController"];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        [self.navigationController pushViewController:ser animated:YES];
    else
    {
        //            UINavigationController *c = [[UINavigationController alloc] initWithRootViewController:ser];
        //            c.modalPresentationStyle = UIModalPresentationFormSheet;
        //            c.navigationBar.barStyle = UIBarStyleBlack;
        //            [self presentViewController:c animated:YES completion:nil];
        //ser.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:ser animated:YES completion:nil];
    }
    
    [s fetchEpisodes:^{
        ser.series = s;
    }];
}

@end
