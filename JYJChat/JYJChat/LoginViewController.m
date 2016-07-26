//
//  LoginViewController.m
//  JYJChat
//
//  Created by JYJ on 16/6/27.
//  Copyright © 2016年 baobeikeji. All rights reserved.
//

#import "LoginViewController.h"
#import "EMSDK.h"

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *usernameField;

@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}


- (IBAction)registeAction:(id)sender {
    NSString *username = self.usernameField.text;
    NSString *password = self.passwordField.text;
    
    if (username.length == 0 || password.length == 0) {
        NSLog(@"请输入账号和密码");
        return;
    }
    
    // 注册
    EMError *error = [[EMClient sharedClient] registerWithUsername:username password:password];
    if (error==nil) {
        NSLog(@"注册成功");
    } else {
        NSLog(@"%@",error.errorDescription);
    }
}

- (IBAction)login:(id)sender {
    
    NSString *username = self.usernameField.text;
    NSString *password = self.passwordField.text;
    
    if (username.length == 0 || password.length == 0) {
        NSLog(@"请输入账号和密码");
        return;
    }

    EMError *error = [[EMClient sharedClient] loginWithUsername:username password:password];
    if (!error) {
        NSLog(@"登录成功");
        
        [[EMClient sharedClient].options setIsAutoLogin:YES];
        // 来到主页面
        self.view.window.rootViewController = [UIStoryboard storyboardWithName:@"Main" bundle:nil].instantiateInitialViewController;
        
    } else {
        NSLog(@"%@",error.errorDescription);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
