//
//  JYJCallController.m
//  JYJChat
//
//  Created by JYJ on 16/7/21.
//  Copyright © 2016年 baobeikeji. All rights reserved.
//

#import "JYJCallController.h"
#import "EMCallSession.h"
#import "EMSDKFull.h"

@interface JYJCallController ()

/** callSession */
@property (nonatomic, strong) EMCallSession *callSession;
/** 是否是发起者 */
@property (nonatomic, assign) BOOL isCaller;
/** 状态字符串 */
@property (nonatomic, copy) NSString *status;
/** 内容 */
@property (nonatomic, weak) UIView *contentView;

/** audioCategory */
@property (nonatomic, copy) NSString *audioCategory;;

/** 时间 */
@property (nonatomic, assign) int time;
/** 通话时间 */
@property (nonatomic, weak)UILabel *callTimeLabel;
/** timer定时器 */
@property (nonatomic, weak) NSTimer *timer;
/** 弱网检测 */
@property (nonatomic, weak) UILabel *networkLabel;
@end

@implementation JYJCallController

- (instancetype)initWithSession:(EMCallSession *)callSession isCaller:(BOOL)isCaller status:(NSString *)status {
    if (self = [super init]) {
        self.callSession = callSession;
        self.isCaller = isCaller;
        self.status = status;
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // 初始化子控件
    [self setupSubViews];
    
    if (self.callSession.type == EMCallTypeVideo) {
        // 初始化摄像头
        [self initCamera];
        
        [self.view bringSubviewToFront:self.contentView];
    }

}

- (void)initCamera {
    //1.对方窗口
    self.callSession.remoteView = [[EMCallRemoteView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.height * 288 / 352, self.view.frame.size.height)];
    [self.view addSubview:self.callSession.remoteView];
    
    //2.自己窗口
    CGFloat width = 80;
    CGFloat height = self.view.frame.size.height / self.view.frame.size.width * width;
    self.callSession.localView = [[EMCallLocalView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 90, CGRectGetMaxY(_statusLabel.frame), width, height)];
    [self.view addSubview:self.callSession.localView];
}


- (void)setupSubViews {
    // 1.背景图片
    UIImageView *imgView = [[UIImageView alloc] init];
    imgView.frame = CGRectMake(0, 0, self.view.width, self.view.height);
    imgView.image = [UIImage imageNamed:@"callBg"];
    [self.view addSubview:imgView];
    
    // contentView
    UIView *contentView = [[UIView alloc] init];
    contentView.frame = imgView.frame;
    contentView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:contentView];
    self.contentView = contentView;
    
    
    // 2.status链接状态
    UILabel *statusLabel = [[UILabel alloc] init];
    statusLabel.frame = CGRectMake(0, 30, contentView.width, 20);
    statusLabel.textAlignment = NSTextAlignmentCenter;
    statusLabel.backgroundColor = [UIColor clearColor];
    [contentView addSubview:statusLabel];
    self.statusLabel = statusLabel;
    
    // 2.时间标签
    UILabel *timeLabel = [[UILabel alloc] init];
    timeLabel.frame = CGRectMake(0, 50, contentView.width, 20);
    timeLabel.textAlignment = NSTextAlignmentCenter;
    timeLabel.backgroundColor = [UIColor clearColor];
    [contentView addSubview:timeLabel];
    self.callTimeLabel = timeLabel;
    
    /** 网络状态 */
    UILabel *networkLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, BXScreenH / 2, BXScreenW, 20)];
    networkLabel.font = [UIFont systemFontOfSize:16.0];
    networkLabel.backgroundColor = [UIColor clearColor];
    networkLabel.textColor = [UIColor whiteColor];
    networkLabel.textAlignment = NSTextAlignmentCenter;
    networkLabel.hidden = YES;
    [contentView addSubview:networkLabel];
    self.networkLabel = networkLabel;
    
    if (self.isCaller) {
        // 3.挂断按钮
        UIButton *cancelBtn = [UIButton buttonWithTitle:@"挂断" titleColor:[UIColor whiteColor] font:[UIFont systemFontOfSize:16] target:self action:@selector(hangupClick)];
        cancelBtn.frame = CGRectMake(30, BXScreenH - 100, BXScreenW - 60, 40);
        cancelBtn.backgroundColor = [UIColor redColor];
        [contentView addSubview:cancelBtn];

    } else {
        // 3.同意按钮
        UIButton *accpetBtn = [UIButton buttonWithTitle:@"同意" titleColor:[UIColor whiteColor] font:[UIFont systemFontOfSize:16] target:self action:@selector(accpetBtnClick)];
        accpetBtn.frame = CGRectMake(30, BXScreenH - 100, BXScreenW / 2 - 60, 40);
        accpetBtn.backgroundColor = [UIColor redColor];
        [contentView addSubview:accpetBtn];
        
        // 4.拒接按钮
        UIButton *rejectBtn = [UIButton buttonWithTitle:@"拒接" titleColor:[UIColor whiteColor] font:[UIFont systemFontOfSize:16] target:self action:@selector(rejectBtnClick)];
        rejectBtn.frame = CGRectMake(BXScreenW / 2 + 30, BXScreenH - 100, BXScreenW / 2 - 60, 40);
        rejectBtn.backgroundColor = [UIColor redColor];
        [contentView addSubview:rejectBtn];
    }
}

#pragma mark - 私有方法

/**
 *  同意按钮点击
 */
- (void)accpetBtnClick {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    self.audioCategory = audioSession.category;
    if(![self.audioCategory isEqualToString:AVAudioSessionCategoryPlayAndRecord]){
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [audioSession setActive:YES error:nil];
    }
    
    [[JYJChatDemoHelper shareHelper] answerCall];
}

/**
 *  拒接按钮点击
 */
- (void)rejectBtnClick {
    // 停止timer
    [self.timer invalidate];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:self.audioCategory error:nil];
    [audioSession setActive:YES error:nil];
    
    [[JYJChatDemoHelper shareHelper] hangupCallWithReason:EMCallEndReasonDecline];
//    [[EMClient sharedClient].callManager endCall:self.callSession.sessionId reason:EMCallEndReasonDecline];
//    [self close];
}
/**
 *  取消按钮点击
 */
- (void)hangupClick {
    // 停止timer
    [self.timer invalidate];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:self.audioCategory error:nil];
    [audioSession setActive:YES error:nil];
    
    [[JYJChatDemoHelper shareHelper] hangupCallWithReason:EMCallEndReasonHangup];
}


/** 开启定时器 */
- (void)startTimer {
    self.time = 0;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timeTimerAction) userInfo:nil repeats:YES];
}

/**
 *  定时器跟新label文字
 */
- (void)timeTimerAction {
    self.time ++;
    int hour = self.time / 3600;
    int min = (self.time - hour * 3600) / 60;
    int sec = self.time - hour * 3600 - min * 60;
    
    NSString *timerStr = nil;
    if (hour > 0) {
        timerStr = [NSString stringWithFormat:@"%zd:%02zd:%02zd", hour, min, sec];
    } else if (min > 0){
        timerStr = [NSString stringWithFormat:@"%02zd:%02d", min, sec];
    } else {
        timerStr = [NSString stringWithFormat:@"00:%zd", sec];
    }
    self.callTimeLabel.text = timerStr;
}


- (void)setNetwork:(EMCallNetworkStatus)status
{
    switch (status) {
        case EMCallNetworkStatusNormal: {
            self.networkLabel.text = @"";
            self.networkLabel.hidden = YES;
        }
            break;
        case EMCallNetworkStatusUnstable: {
            self.networkLabel.text = @"当前网络不稳定";
            self.networkLabel.hidden = NO;
        }
            break;
        case EMCallNetworkStatusNoData: {
            self.networkLabel.text = @"没有通话数据";
            self.networkLabel.hidden = NO;
        }
            break;
        default:
            break;
    }
}


- (void)close {
    self.callSession.remoteView.hidden = YES;
    self.callSession = nil;
    self.contentView = nil;
    
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[AVAudioSession sharedInstance] setActive:NO error:nil];
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}


@end
