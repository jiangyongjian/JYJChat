//
//  JYJSettingViewController.m
//  JYJChat
//
//  Created by JYJ on 16/6/29.
//  Copyright © 2016年 baobeikeji. All rights reserved.
//

#import "JYJSettingViewController.h"
#import "EMSDK.h"

@interface JYJSettingViewController ()
- (IBAction)logoutAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *logoutBtn;

@end

@implementation JYJSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 当前登录的用户名
    NSString *loginUsername = [[EMClient sharedClient] currentUsername];
    
    NSString *title = [NSString stringWithFormat:@"log out(%@)",loginUsername];
    
    //1.设置退出按钮的文字
    [self.logoutBtn setTitle:title forState:UIControlStateNormal];

}

- (IBAction)logoutAction:(id)sender {
    //UnbindDeviceToken 不绑定DeviceToken
    // DeviceToken 推送用
    
    EMError *error = [[EMClient sharedClient] logout:YES];
    if (!error) {
        NSLog(@"退出成功");
        // 回到登录界面
        self.view.window.rootViewController = [UIStoryboard storyboardWithName:@"LoginViewController" bundle:nil].instantiateInitialViewController;
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
