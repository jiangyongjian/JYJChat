//
//  JYJChatDemoHelper.m
//  JYJChat
//
//  Created by JYJ on 16/7/22.
//  Copyright © 2016年 baobeikeji. All rights reserved.
//

#import "JYJChatDemoHelper.h"
#import "JYJCallController.h"
#import "BXTabBarController.h"


@interface JYJChatDemoHelper () <EMCallManagerDelegate>
/** callSession */
@property (nonatomic, strong) EMCallSession *callSession;
/** callController */
@property (nonatomic, strong) JYJCallController *callController;
/** 等待对方接听的定时器 */
@property (nonatomic, weak) NSTimer *watingCallTimer;
@end

static JYJChatDemoHelper *helper = nil;
@implementation JYJChatDemoHelper

+ (instancetype)shareHelper {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper = [[JYJChatDemoHelper alloc] init];
    });
    return helper;
}

- (id)init {
    if (self = [super init]) {
        // 初始化
        [self setupHelper];
    }
    return self;
}

/** 初始化 */
- (void)setupHelper {
    // 添加实时通话代理
    [[EMClient sharedClient].callManager addDelegate:self delegateQueue:nil];
    
    // 添加通知
    [BXNoteCenter addObserver:self selector:@selector(makeCall:) name:BXNotificationCall object:nil];
}

- (void)dealloc {
    //移除消息回调
    [[EMClient sharedClient].callManager removeDelegate:self];
}
#pragma mark - 私有方法
- (void)makeCall:(NSNotification *)note {
    if (note.userInfo) {
        [self makeCallWithUsername:note.userInfo[BXConversationId] isVideo:[note.userInfo[BXConversationType] boolValue]];
    }
}

/** 调用JYJCallController */
- (void)makeCallWithUsername:(NSString *)aUsername
                     isVideo:(BOOL)aIsVideo
{
    BXLog(@"%@", aUsername);
    if ([aUsername length] == 0) return;

    if (aIsVideo) {
        EMCallSession *callSession = [[EMClient sharedClient].callManager makeVideoCall:aUsername error:nil];
        self.callSession = callSession;
    } else {
        EMCallSession *callSession = [[EMClient sharedClient].callManager makeVoiceCall:aUsername error:nil];
        self.callSession = callSession;
    }
    
    if(self.callSession){
        [self startCallTimer];
        
        self.callController = [[JYJCallController alloc] initWithSession:self.callSession isCaller:YES status:@"正在连接中..."];
        [self.mainTabBarVC presentViewController:self.callController animated:YES completion:nil];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"创建实时通话失败，请稍后重试" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
    }
}

- (void)hangupCallWithReason:(EMCallEndReason)aReason {
    [self stopCallTimer];
    
    if (self.callSession) {
        [[EMClient sharedClient].callManager endCall:_callSession.sessionId reason:aReason];
    }
    self.callSession = nil;
    [self.callController close];
    self.callController = nil;
}

/** 等待对方接听的定时器 */
- (void)startCallTimer {
    self.watingCallTimer = [NSTimer scheduledTimerWithTimeInterval:50 target:self selector:@selector(cancelCall) userInfo:nil repeats:NO];
}

- (void)cancelCall {
    [self hangupCallWithReason:EMCallEndReasonNoResponse];
    // 弹框提示
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"没有响应，自动挂断" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alertView show];
}

/** 停止等待的定时器 */
- (void)stopCallTimer {
    if (self.watingCallTimer == nil) return;
    [self.watingCallTimer invalidate];
    self.watingCallTimer = nil;
}

- (void)answerCall {
    if (self.callSession) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            EMError *error = [[EMClient sharedClient].callManager answerCall:self.callSession.sessionId];
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error.code == EMErrorNetworkUnavailable) {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"网络错误" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                        [alertView show];
                    } else {
                        [self hangupCallWithReason:EMCallEndReasonFailed];
                    }
                });
            }
        });
    }
}

#pragma mark - EMCallManagerDelegate
/*
 *  用户A拨打用户B，用户B会收到这个回调
 *
 *  @param aSession  会话实例
 */
- (void)didReceiveCallIncoming:(EMCallSession *)aSession {
    if (self.callSession && self.callSession.status != EMCallSessionStatusDisconnected) {
        [[EMClient sharedClient].callManager endCall:aSession.sessionId reason:EMCallEndReasonBusy];
    }
    
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        [[EMClient sharedClient].callManager endCall:aSession.sessionId reason:EMCallEndReasonFailed];
    }
    
    self.callSession = aSession;
    if (self.callSession) {
        [self startCallTimer];
        
        self.callController = [[JYJCallController alloc] initWithSession:self.callSession isCaller:NO status:@"连接建立完成"];
        [self.mainTabBarVC presentViewController:self.callController animated:YES completion:nil];
    }
}
/*
 *  通话通道建立完成，用户A和用户B都会收到这个回调
 *
 *  @param aSession  会话实例
 */
- (void)didReceiveCallConnected:(EMCallSession *)aSession {
    if ([aSession.sessionId isEqualToString:self.callSession.sessionId]) {
        self.callController.statusLabel.text = @"连接建立完成";
        
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [audioSession setActive:YES error:nil];
    }
}

/*
 *  用户B同意用户A拨打的通话后，用户A会收到这个回调
 *
 *  @param aSession  会话实例
 */
- (void)didReceiveCallAccepted:(EMCallSession *)aSession {
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        [[EMClient sharedClient].callManager endCall:aSession.sessionId reason:EMCallEndReasonFailed];
    }
    
    if ([aSession.sessionId isEqualToString:self.callSession.sessionId]) {
        [self stopCallTimer];
        
        NSString *connectStr = aSession.connectType == EMCallConnectTypeRelay ? @"Relay" : @"Direct";
        self.callController.statusLabel.text = [NSString stringWithFormat:@"%@ - %@", @"可以说话了...", connectStr];
        [self.callController startTimer];
    }
}

/*
 *  1. 用户A或用户B结束通话后，对方会收到该回调
 *  2. 通话出现错误，双方都会收到该回调
 *
 *  @param aSession  会话实例
 *  @param aReason   结束原因
 *  @param aError    错误
 */
- (void)didReceiveCallTerminated:(EMCallSession *)aSession reason:(EMCallEndReason)aReason error:(EMError *)aError {
    if ([aSession.sessionId isEqualToString:self.callSession.sessionId]) {
        [self stopCallTimer];
        
        self.callSession = nil;
        [self.callController close];
        
        if (aReason != EMCallEndReasonHangup) {
            NSString *reasonStr = @"";
            switch (aReason) {
                case EMCallEndReasonNoResponse: {
                    reasonStr = @"对方没有回应";
                }
                    break;
                case EMCallEndReasonDecline: {
                    reasonStr = @"拒接";
                }
                    break;
                case EMCallEndReasonBusy: {
                    reasonStr = @"正在通话中...";
                }
                    break;
                case EMCallEndReasonFailed: {
                    reasonStr = @"建立连接失败";
                }
                    break;
                default:
                    break;
            }
            
            if (aError) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:aError.errorDescription delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                [alertView show];
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:reasonStr delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                [alertView show];
            }
        }
    }
}

/*
  *  用户A和用户B正在通话中，用户A的网络状态出现不稳定，用户A会收到该回调
  *
  *  @param aSession  会话实例
  *  @param aStatus   当前状态
  */
- (void)didReceiveCallNetworkChanged:(EMCallSession *)aSession status:(EMCallNetworkStatus)aStatus {
    if ([aSession.sessionId isEqualToString:self.callSession.sessionId]) {
        [self.callController setNetwork:aStatus];
    }
}

@end
