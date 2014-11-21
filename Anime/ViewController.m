//
//  ViewController.m
//  Anime
//
//  Created by David Quesada on 11/6/14.
//  Copyright (c) 2014 David Quesada. All rights reserved.
//

#import "ViewController.h"
#import "SeriesViewController.h"
#import "HTMLReader.h"
#import "Series.h"
#import "SeriesRequest.h"

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
{
    IBOutlet UITableView *tableView;
    
//    NSMutableArray *things;
    NSArray *series;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self doSearch:@"Hunter x HUNTER"];
    });
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSString *text = searchBar.text;
    [searchBar resignFirstResponder];
    
    [self doSearch:text];
}

-(void)doSearch:(NSString *)text
{
    SeriesRequest *req = [SeriesRequest searchSeriesRequestForQuery:text];
    [req loadPageOfSeries:^(NSArray *nextPage) {
        series = nextPage;
        [tableView reloadData];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return series.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"NOPE"];
    
    Series *thing = series[indexPath.row];
    
    cell.textLabel.text = thing.seriesTitle;
    cell.detailTextLabel.text = thing.seriesStatusDescription;
    
    return cell;
}

-(void)tableView:(UITableView *)__tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [__tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Series *s = series[indexPath.row];
    
    [s fetchEpisodes:^{
        
        SeriesViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"seriesViewController"];
//            vc.docpath = s.docpath;
        vc.series = s;
        [self.navigationController pushViewController:vc animated:YES];
        
    }];
}

@end
