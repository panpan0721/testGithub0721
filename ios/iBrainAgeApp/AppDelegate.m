/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "AppDelegate.h"
//#import <CodePush/CodePush.h>
#import "CodePush.h"
#import <RCTJPushModule.h>
#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#import <UserNotifications/UserNotifications.h>
#endif

#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>
#import <React/RCTLinkingManager.h>
#import "RNDeepLink/RNDeepLink.h"

#import "Orientation.h"
#import "SplashScreen.h"
#import "RNUMConfigure.h"
#import "SensorsAnalyticsSDK.h"
#import <UMAnalytics/MobClick.h>


@implementation AppDelegate
#ifdef DEBUG
#define SA_SERVER_URL @"https://shen.ibrainbaby.net:888/sa?project=default"
#else
#define SA_SERVER_URL @"https://shen.ibrainbaby.net:888/sa?project=production"
#endif


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
  if ([url.scheme isEqualToString:@"dl070b5d46d7edf9bf"]) {
    return [RNDeepLink handleURL:url];
  }

  return [RCTLinkingManager application:application openURL:url
                      sourceApplication:sourceApplication annotation:annotation];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
 	return [RNDeepLink handleURL:url];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler {
 	return [RNDeepLink handleUserActivity:userActivity];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [self initSensorsAnalyticsWithLaunchOptions:launchOptions];
  [UMConfigure setLogEnabled:YES];
  [MobClick setScenarioType:E_UM_NORMAL];

  [RNUMConfigure initWithAppkey:@"5c499018b465f588ee00159e" channel:@"App Store"];
//  [MobClick startWithConfigure:UMConfigInstance];

    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
 #ifdef NSFoundationVersionNumber_iOS_9_x_Max
    JPUSHRegisterEntity * entity = [[JPUSHRegisterEntity alloc] init];
     entity.types = UNAuthorizationOptionAlert|UNAuthorizationOptionBadge|UNAuthorizationOptionSound;
     [JPUSHService registerForRemoteNotificationConfig:entity delegate:self];

#endif
} else if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
    [JPUSHService registerForRemoteNotificationTypes:(UIUserNotificationTypeBadge |
                                                      UIUserNotificationTypeSound |
                                                      UIUserNotificationTypeAlert)
                                          categories:nil];
  } else {
    [JPUSHService registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                      UIRemoteNotificationTypeSound |
                                                      UIRemoteNotificationTypeAlert)
                                          categories:nil];
  }

  [JPUSHService setupWithOption:launchOptions appKey:@"e88c98d933f7856a86dcbde6"
                        channel:nil apsForProduction:nil];
  NSURL *jsCodeLocation;


#ifdef DEBUG
    jsCodeLocation = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index.ios" fallbackResource:nil];
#else
    jsCodeLocation = [CodePush bundleURL];
#endif

  RCTRootView *rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                      moduleName:@"iBrainAgeApp"
                                               initialProperties:nil
                                                   launchOptions:launchOptions];
  rootView.backgroundColor = [[UIColor alloc] initWithRed:1.0f green:1.0f blue:1.0f alpha:1];

  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  UIViewController *rootViewController = [UIViewController new];
  rootViewController.view = rootView;
  self.window.rootViewController = rootViewController;
  [self.window makeKeyAndVisible];
  [SplashScreen show];
  return YES;
}
- (void)initSensorsAnalyticsWithLaunchOptions:(NSDictionary *)launchOptions {

  // 初始化 SDK
  [SensorsAnalyticsSDK sharedInstanceWithServerURL:SA_SERVER_URL andLaunchOptions:launchOptions];


  // 打开自动采集, 并指定追踪哪些 AutoTrack 事件
  [[SensorsAnalyticsSDK sharedInstance] enableAutoTrack:SensorsAnalyticsEventTypeAppStart|
   SensorsAnalyticsEventTypeAppEnd];

  // 记录激活事件，追踪渠道效果
  [[SensorsAnalyticsSDK sharedInstance] trackInstallation:@"AppInstall"];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
[JPUSHService registerDeviceToken:deviceToken];
}
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
[[NSNotificationCenter defaultCenter] postNotificationName:kJPFDidReceiveRemoteNotification object:userInfo];
}
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)   (UIBackgroundFetchResult))completionHandler {
[[NSNotificationCenter defaultCenter] postNotificationName:kJPFDidReceiveRemoteNotification object:userInfo];
}

- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(NSInteger))completionHandler {
 NSDictionary * userInfo = notification.request.content.userInfo;
 if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
 [JPUSHService handleRemoteNotification:userInfo];
 [[NSNotificationCenter defaultCenter] postNotificationName:kJPFDidReceiveRemoteNotification object:userInfo];
    }
 completionHandler(UNNotificationPresentationOptionAlert);
}
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
NSDictionary * userInfo = response.notification.request.content.userInfo;
if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
[JPUSHService handleRemoteNotification:userInfo];
[[NSNotificationCenter defaultCenter] postNotificationName:kJPFOpenNotification object:userInfo];
}
completionHandler();
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
  return [Orientation getOrientation];
}
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
[[NSNotificationCenter defaultCenter] postNotificationName:kJPFDidReceiveRemoteNotification object:notification.userInfo];
}
@end
