//
//  JYJCallController.h
//  JYJChat
//
//  Created by JYJ on 16/7/21.
//  Copyright © 2016年 baobeikeji. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@class EMCallSession;
@interface JYJCallController : UIViewController
- (instancetype)initWithSession:(EMCallSession *)callSession isCaller:(BOOL)isCaller status:(NSString *)status;
/** 链接状态 */
@property (nonatomic, weak)UILabel *statusLabel;

/** 开启定时器 */
- (void)startTimer;
/** 关闭界面 */
- (void)close;

- (void)setNetwork:(EMCallNetworkStatus)status;

@end
