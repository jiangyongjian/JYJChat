//
//  JYJChatCell.m
//  JYJChat
//
//  Created by JYJ on 16/6/29.
//  Copyright © 2016年 baobeikeji. All rights reserved.
//

#import "JYJChatCell.h"
#import "EMCDDeviceManager.h"
#import "JYJAudioPlayTool.h"
#import "UIImageView+WebCache.h"

@interface JYJChatCell ()
/** 图片 */
@property (nonatomic, weak) UIImage *image;
/** 占位图片 */
@property (nonatomic, strong)  UIImageView *chatImageView;

@end

@implementation JYJChatCell

- (UIImageView *)chatImageView {
    if (!_chatImageView) {
        UIImageView *chatImageView = [[UIImageView alloc] init];
        chatImageView.backgroundColor = [UIColor redColor];
        self.chatImageView = chatImageView;
    }
    return _chatImageView;
}


- (void)awakeFromNib {
    // 1.给label添加敲击手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(messageLabelTap:)];
    [self.messageLabel addGestureRecognizer:tap];
}

#pragma mark - messageLabel点击触发方法
- (void)messageLabelTap:(UITapGestureRecognizer *)recognizer {
    // 播放音乐
    // 只有当前的类型是音乐的时候才能播放
    if (self.message.body.type == EMMessageBodyTypeVoice) {
        BOOL receiver = [self.reuseIdentifier isEqualToString:ReceiverCell];
        [JYJAudioPlayTool playWithMessage:self.message msgLabel:self.messageLabel receiver:receiver];
    }
}

- (void)setMessage:(EMMessage *)message {
    _message = message;
    
    // 重用时，把聊天图片控件移除
    [self.chatImageView removeFromSuperview];
    
    // 1.获取消息体
    EMMessageBody *msgBody = message.body;
    if (msgBody.type == EMMessageBodyTypeText) { // 收到的文字消息
        EMTextMessageBody *textBody = (EMTextMessageBody *)msgBody;
        self.messageLabel.text = textBody.text;
    } else if (msgBody.type == EMMessageBodyTypeVoice){ // 语言消息
        self.messageLabel.attributedText = [self voiceAttr];
    } else if (msgBody.type == EMMessageBodyTypeImage) {
        [self showImage];
    } else {
        self.messageLabel.text = @"未知类型";
    }
}

- (void)showImage {
    EMImageMessageBody *imageBody = (EMImageMessageBody *)self.message.body;
    CGRect thumbnailFrm = (CGRect){0, 0, {0, 0}};
    
//    NSLog(@"%@", NSStringFromCGSize(imageBody.size));
    NSData *imageData = [NSData dataWithContentsOfFile:imageBody.localPath];
    if (imageData.length) {
        self.image = [UIImage imageWithData:imageData];
    }
    
    
    // 设置Label的尺寸足够显示UIImageView
    NSTextAttachment *imageAttach = [[NSTextAttachment alloc] init];
    
    // 1. cell里面添加一个UIImageView
    [self.messageLabel addSubview:self.chatImageView];
    
    // 3.下载图片
//    NSLog(@"thumbnailLocalPath %@",imageBody.thumbnailLocalPath);
//    NSLog(@"thumbnailRemotePath %@",imageBody.thumbnailRemotePath);
    NSFileManager *manager = [NSFileManager defaultManager];
//    NSLog(@"%@", NSStringFromCGSize(imageBody.thumbnailSize));
    //如果本地图片存在，直接从本地显示图片
    UIImage *palceImage = [UIImage imageNamed:@"imageDownloadFail"];
    if ([manager fileExistsAtPath:imageBody.thumbnailLocalPath]) {
#warning 本地路径使用fileURLWithPath方法
        [self.chatImageView sd_setImageWithURL:[NSURL fileURLWithPath:imageBody.thumbnailLocalPath] placeholderImage:palceImage];
        
    } else { // 如果本地图片不存，从网络加载图片
        [self.chatImageView sd_setImageWithURL:[NSURL URLWithString:imageBody.thumbnailRemotePath] placeholderImage:palceImage];
    }
    
    CGSize retSize = self.chatImageView.image.size;
    if (retSize.width == 0 || retSize.height == 0) {
        retSize.width = 120;
        retSize.height = 120;
    }
    else if (retSize.width > retSize.height) {
        CGFloat height =  120 / retSize.width * retSize.height;
        retSize.height = height;
        retSize.width = 120;
    }
    else {
        CGFloat width = 120 / retSize.height * retSize.width;
        retSize.width = width;
        retSize.height = 120;
    }
    thumbnailFrm = (CGRect){0, 0, retSize};
    
    imageAttach.bounds = thumbnailFrm;
    NSAttributedString *imgAttr = [NSAttributedString attributedStringWithAttachment:imageAttach];
    self.messageLabel.attributedText = imgAttr;
    // 2.cell里添加一个UIImageView
    self.chatImageView.frame = thumbnailFrm;
}


- (UIImage *)scaleImage:(UIImage *)image toScale:(float)scaleSize
{
    UIGraphicsBeginImageContext(CGSizeMake(image.size.width * scaleSize, image.size.height * scaleSize));
    [image drawInRect:CGRectMake(0, 0, image.size.width * scaleSize, image.size.height * scaleSize)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}


- (NSAttributedString *)voiceAttr {
    // 创建一个可变的富文本
    NSMutableAttributedString *voiceAttr = [[NSMutableAttributedString alloc] init];
    // 获取时间
    EMVideoMessageBody *voiceBody = (EMVideoMessageBody *)self.message.body;
    NSUInteger duration = voiceBody.duration;
    NSString *timeStr = [NSString stringWithFormat:@"%ld", duration];
    NSAttributedString *timeAttr = [[NSAttributedString alloc] initWithString:timeStr];
    
    // 1.接收方：富文本 = 图片 + 时间
    if ([self.reuseIdentifier isEqualToString:ReceiverCell]) {
        // 1.1 接收方的语言图片
        UIImage *receiverImg = [UIImage imageNamed:@"chat_receiver_audio_playing_full"];
        
        // 1.2 创建图片附件
        NSTextAttachment *imgAttachment = [[NSTextAttachment alloc] init];
        imgAttachment.image = receiverImg;
        
        // 1.3图片富文本
        NSAttributedString *imgAttr = [NSAttributedString attributedStringWithAttachment:imgAttachment];
        [voiceAttr appendAttributedString:imgAttr];
        imgAttachment.bounds = CGRectMake(0, -4, 20, 20);
        
        // 1.4创建时间富文本
        [voiceAttr appendAttributedString:timeAttr];
    } else { // 2.发送方：富文本 = 时间 + 图片
        // 2.1 拼接时间
        [voiceAttr appendAttributedString:timeAttr];

        // 2.2 发送方的语言图片
        UIImage *receiverImg = [UIImage imageNamed:@"chat_sender_audio_playing_full"];
        
        // 2.3 创建图片附件
        NSTextAttachment *imgAttachment = [[NSTextAttachment alloc] init];
        imgAttachment.image = receiverImg;
        imgAttachment.bounds = CGRectMake(0, -4, 20, 20);
        
        // 2.4图片富文本
        NSAttributedString *imgAttr = [NSAttributedString attributedStringWithAttachment:imgAttachment];
        [voiceAttr appendAttributedString:imgAttr];
    }
    return [voiceAttr copy];
}



- (CGFloat)cellHeight {
    // 1.从新布局子控件
    [self layoutIfNeeded];
    
    
    return 5 + 10 + self.messageLabel.bounds.size.height + 10 + 5;
}

@end
