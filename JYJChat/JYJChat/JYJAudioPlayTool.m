//
//  JYJAudioPlayTool.m
//  JYJChat
//
//  Created by JYJ on 16/7/7.
//  Copyright © 2016年 baobeikeji. All rights reserved.
//

#import "JYJAudioPlayTool.h"
#import "EMCDDeviceManager.h"

/** 全局的正在执行动画的ImageView */
static UIImageView *animatingImageView;

@implementation JYJAudioPlayTool

+ (void)playWithMessage:(EMMessage *)msg msgLabel:(UILabel *)msgLabel receiver:(BOOL)receiver {
    // 把以前的动画移除
    [animatingImageView stopAnimating];
    [animatingImageView removeFromSuperview];
    // 1.播放语音
    // 获取语音路径
    EMVideoMessageBody *voiceBody = (EMVideoMessageBody *)msg.body;
    
    // 本地语音文件路径
    NSString *path = voiceBody.localPath;
    
    // 如果本地语音不存在，使用服务器语音
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]) {
        path = voiceBody.remotePath;
    }
    
    [[EMCDDeviceManager sharedInstance] asyncPlayingWithPath:path completion:^(NSError *error) {
        NSLog(@"播放完成 %@", error);
        // 移除动画
        [animatingImageView stopAnimating];
        [animatingImageView removeFromSuperview];
    }];
    
    // 2. 添加动画
    // 2.1 创建一个UIImageView 添加到label上
    UIImageView *imgView = [[UIImageView alloc] init];
    [msgLabel addSubview:imgView];
    
    // 2.2添加动画图片
    if (receiver) {
        imgView.animationImages = @[[UIImage imageNamed:@"chat_receiver_audio_playing000"],
                                    [UIImage imageNamed:@"chat_receiver_audio_playing001"],
                                    [UIImage imageNamed:@"chat_receiver_audio_playing002"],
                                    [UIImage imageNamed:@"chat_receiver_audio_playing003"]];
        imgView.frame = CGRectMake(0, 0, 20, 20);
    } else {
        imgView.animationImages = @[[UIImage imageNamed:@"chat_sender_audio_playing_000"],
                                    [UIImage imageNamed:@"chat_sender_audio_playing_001"],
                                    [UIImage imageNamed:@"chat_sender_audio_playing_002"],
                                    [UIImage imageNamed:@"chat_sender_audio_playing_003"]];
        imgView.frame = CGRectMake(msgLabel.bounds.size.width - 20, 0, 20, 20);
    }
    imgView.animationDuration = 1;
    [imgView startAnimating];
    animatingImageView = imgView;
}

+ (void)stop {
    // 停止播放影音
    [[EMCDDeviceManager sharedInstance] stopPlaying];
    
    // 移除动画
    [animatingImageView stopAnimating];
    [animatingImageView removeFromSuperview];
}

@end
