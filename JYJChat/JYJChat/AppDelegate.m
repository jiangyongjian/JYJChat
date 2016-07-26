//
//  AppDelegate.m
//  JYJChat
//
//  Created by JYJ on 16/6/27.
//  Copyright © 2016年 baobeikeji. All rights reserved.
//

#import "AppDelegate.h"
#import "EMSDK.h"

@interface AppDelegate () <EMClientDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //AppKey:注册的AppKey，详细见下面注释。
    //apnsCertName:推送证书名（不需要加后缀），详细见下面注释。
    EMOptions *options = [EMOptions optionsWithAppkey:@"542829817#jyjchat"];
//    options.apnsCertName = @"istore_dev";
//    options.enableConsoleLog = YES;
    [[EMClient sharedClient] initializeSDKWithOptions:options];

    
    /**
     *  2.监听自动登录的状态
     *  设置chatManager代理
     *  写个nil 默认代理会在主线程调用
     */
    [[EMClient sharedClient] addDelegate:self delegateQueue:nil];
    BOOL isAutoLogin = [EMClient sharedClient].options.isAutoLogin;
    NSLog(@"%zd", isAutoLogin);
    if (isAutoLogin) {
        self.window.rootViewController = [UIStoryboard storyboardWithName:@"Main" bundle:nil].instantiateInitialViewController;
    }
    
    return YES;
}

#pragma mark - 自动登录的回调
- (void)didAutoLoginWithError:(EMError *)aError {
    if (!aError) {
        NSLog(@"自动登录成功");
    } else {
        NSLog(@"自动登录失败 %@", aError);
    }
}

- (void)dealloc {
    // 移除聊天管理器的代理
    [[EMClient sharedClient] removeDelegate:self];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

// APP进入后台
- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[EMClient sharedClient] applicationDidEnterBackground:application];
}

// APP将要从后台返回
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[EMClient sharedClient] applicationWillEnterForeground:application];
}
- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
