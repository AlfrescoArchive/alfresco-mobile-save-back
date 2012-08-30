//
//  AppDelegate.m
//  SaveBack
//
//  Created by Mike Hatfield on 28/08/2012.
//  Copyright (c) 2012 Alfresco. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"

@implementation AppDelegate

NSString * const FILE_URL = @"file://";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.viewController = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSString *urlToMatch = [[url absoluteString] lowercaseString];
    if ([urlToMatch hasPrefix:FILE_URL])
    {
        return [self.viewController handleFileOpenURL:url annotation:annotation];
    }

    return NO;
}

@end
