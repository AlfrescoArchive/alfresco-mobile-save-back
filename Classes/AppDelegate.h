//
//  AppDelegate.h
//  SaveBack
//
//  Created by Mike Hatfield on 28/08/2012.
//  Copyright (c) 2012 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MainViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) MainViewController *viewController;

@end
