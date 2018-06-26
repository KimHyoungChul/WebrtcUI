//
//  CommonUtil.m
//  SipVideoPluginTest
//
//  Created by SCNDev1 on 1/27/17.
//
//

#import "CommonUtil.h"

@implementation CommonUtil

+ (UIViewController *)topViewController:(UIViewController *)rootViewController
{
    if (rootViewController.presentedViewController == nil) {
        return rootViewController;
    }
    
    if ([rootViewController.presentedViewController isMemberOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = (UIViewController *)[[navigationController viewControllers] lastObject];
        return [self topViewController:lastViewController];
    }
    
    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [self topViewController:presentedViewController];
}


// test start
//            UILocalNotification *notification = [[UILocalNotification alloc] init];
//            notification.alertBody = @"Test";
//            notification.fireDate = [[[NSDate alloc] init] dateByAddingTimeInterval:5.0f];
//            notification.category = NotificationCategoryIdent1;
//
//            [[UIApplication sharedApplication] scheduleLocalNotification:notification];
// test end

@end
