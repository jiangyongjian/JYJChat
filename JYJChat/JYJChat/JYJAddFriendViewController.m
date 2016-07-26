//
//  JYJAddFriendViewController.m
//  JYJChat
//
//  Created by JYJ on 16/6/28.
//  Copyright © 2016年 baobeikeji. All rights reserved.
//

#import "JYJAddFriendViewController.h"
#import "EMSDK.h"

@interface JYJAddFriendViewController ()
@property (weak, nonatomic) IBOutlet UITextField *textField;
- (IBAction)addFriendAction:(id)sender;

@end

@implementation JYJAddFriendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
#warning 代理放在Conversaton控制器比较好
    // 添加（聊天管理器）代理
    //    [[EaseMob sharedInstance].chatManager addDelegate:self delegateQueue:nil];
}

- (IBAction)addFriendAction:(id)sender {
    // 添加好友
    
    // 1.获取要添加好友的名字
    NSString *username = self.textField.text;

    // 2.像服务器发送一个添加好友的请求
    // buddy 哥们
    // message ： 请求添加好友的 额外信息
    
    NSString *loginUsername = [EMClient sharedClient].currentUsername;
    NSLog(@"%@", loginUsername);
    NSString *message = [@"我是" stringByAppendingString:loginUsername];
    EMError *error = [[EMClient sharedClient].contactManager addContact:username message:message];
    if (!error) {
        NSLog(@"添加成功");
    } else {
        NSLog(@"添加好友有问题 %@",error);
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
