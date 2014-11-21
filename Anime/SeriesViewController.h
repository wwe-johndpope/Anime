//
//  SeriesViewController.h
//  Anime
//
//  Created by David Quesada on 11/9/14.
//  Copyright (c) 2014 David Quesada. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Series;

@interface SeriesViewController : UITableViewController

@property Series *series;

#warning Deprecated
//@property NSString *docpath;

@end
