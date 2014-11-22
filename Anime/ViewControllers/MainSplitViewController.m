//
//  MainSplitViewController.m
//  Anime
//
//  Created by David Quesada on 11/21/14.
//  Copyright (c) 2014 David Quesada. All rights reserved.
//

#import "MainSplitViewController.h"
#import "BlankDetailViewController.h"
#import "SearchViewController.h"
#import "MasterNavigationController.h"

@interface MainSplitViewController ()<UISplitViewControllerDelegate>

@end

@implementation MainSplitViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.delegate = self;
    self.presentsWithGesture = NO;
    self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - UISplitViewControllerDelegate

-(BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController
{
    if ([secondaryViewController isKindOfClass:[BlankDetailViewController class]])
        return YES;
    return NO;
}

-(UIViewController *)splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController
{
    MasterNavigationController *nav = (id)primaryViewController;
    UIViewController *top = [nav topViewController];
    
    if ([top isKindOfClass:[SearchViewController class]])
        return [self.storyboard instantiateViewControllerWithIdentifier:@"blankDetail"];
    
    return nil;
}


@end
