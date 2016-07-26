//
//  UIViewController+BXExtension.m
//  BXInsurenceBroker
//
//  Created by JYJ on 16/6/27.
//  Copyright © 2016年 baobeikeji. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

@implementation UIViewController (BXExtension)

+ (void)load {
    // 获取到UIViewController中presentViewController对应的method
    Method presentVC = class_getInstanceMethod(self, NSSelectorFromString(@"presentViewController:animated:completion:"));
    Method bx_presentVC = class_getInstanceMethod(self, @selector(bx_presentViewController:animated:completion:));
    
    // 将目标函数的原实现绑定到bxdd_presentViewController:animated:completion:方法上
    IMP presentVCImp = method_getImplementation(presentVC);
    class_addMethod(self, NSSelectorFromString(@"bxdd_presentViewController:animated:completion:"), presentVCImp, method_getTypeEncoding(presentVC));
    
    // 然后用我们自己的函数的实现，替换目标函数对应的实现
    IMP bx_presentVCImp = method_getImplementation(bx_presentVC);
    class_replaceMethod(self, NSSelectorFromString(@"presentViewController:animated:completion:"), bx_presentVCImp, method_getTypeEncoding(presentVC));
    
    
    // 获取到UIViewController中dismissViewController对应的method
    Method dismissVC = class_getInstanceMethod(self, NSSelectorFromString(@"dismissViewControllerAnimated:completion:"));
    Method bx_dismissVC = class_getInstanceMethod(self, @selector(bx_dismissViewControllerAnimated:completion:));
    
    // 将目标函数的原实现绑定到bxdd_dismissViewControllerAnimated:completion:方法上
    IMP dismissVCImp = method_getImplementation(dismissVC);
    class_addMethod(self, NSSelectorFromString(@"bxdd_dismissViewControllerAnimated:completion:"), dismissVCImp, method_getTypeEncoding(dismissVC));
    
    // 然后用我们自己的函数的实现，替换目标函数对应的实现
    IMP bx_dismissVCImp = method_getImplementation(bx_dismissVC);
    class_replaceMethod(self, NSSelectorFromString(@"dismissViewControllerAnimated:completion:"), bx_dismissVCImp, method_getTypeEncoding(dismissVC));
}

- (void)bx_presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion
{
    typedef void (*BXMsgSend)(id, SEL, UIViewController *, BOOL, void (^)(void));
    BXMsgSend msgSend = (BXMsgSend)objc_msgSend;
    msgSend(self, NSSelectorFromString(@"bxdd_presentViewController:animated:completion:"), viewControllerToPresent, flag, completion);
    
    if (![viewControllerToPresent isKindOfClass:[UINavigationController class]]) {
        return;
    }
    UINavigationController *nav = (UINavigationController *)viewControllerToPresent;
    
    [nav.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // 特殊处理没有安装新浪微博弹出的控制器
        if ([obj isKindOfClass:NSClassFromString(@"WBSDKComposerWebViewController")] || [obj isKindOfClass:NSClassFromString(@"CNContactPickerViewController")]) {
            // 通过appearance对象能修改整个项目中所有statusBar的样式
            UINavigationBar *appearance = [UINavigationBar appearance];
            // 设置导航条的背景
            [appearance setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
            // 设置文字
            NSMutableDictionary *att = [NSMutableDictionary dictionary];
            att[NSForegroundColorAttributeName] = [UIColor blackColor];
            [appearance setTitleTextAttributes:att];
            // 3.设置状态栏
            [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
            *stop = YES;
        }
    }];
}

- (void)bx_dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    typedef void (*BXMsgSend)(id, SEL, BOOL, void (^)(void));
    BXMsgSend msgSend = (BXMsgSend)objc_msgSend;
    msgSend(self, NSSelectorFromString(@"bxdd_dismissViewControllerAnimated:completion:"), flag, completion);

    if ([self isKindOfClass:NSClassFromString(@"WBSDKComposerWebViewController")] || [self isKindOfClass:NSClassFromString(@"ABPeoplePickerNavigationController")]) {
        // 通过appearance对象能修改整个项目中所有statusBarStyle的样式
        UINavigationBar *appearance = [UINavigationBar appearance];
        // 1.设置导航条的背景
        [appearance setBackgroundImage:[UIImage createImageWithColor:The_MainColor] forBarMetrics:UIBarMetricsDefault];
        // 2.设置文字颜色
        NSMutableDictionary *att = [NSMutableDictionary dictionary];
        att[NSForegroundColorAttributeName] = [UIColor whiteColor];
        [appearance setTitleTextAttributes:att];
        // 3.设置状态栏
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    }
}

@end
