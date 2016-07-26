//
//  BXTabBarController.m
//  JYJChat
//
//  Created by JYJ on 16/7/22.
//  Copyright © 2016年 baobeikeji. All rights reserved.
//

#import "BXTabBarController.h"
#import "JYJChatDemoHelper.h"

@implementation BXTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [JYJChatDemoHelper shareHelper].mainTabBarVC = self;
}

@end
