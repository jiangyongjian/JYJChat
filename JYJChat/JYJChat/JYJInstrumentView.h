//
//  JYJInstrumentView.h
//  JYJChat
//
//  Created by JYJ on 16/7/19.
//  Copyright © 2016年 baobeikeji. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, JYJInstrumentViewButtonType) {
    JYJInstrumentViewButtonTypePicture, // 图片相册
    JYJInstrumentViewButtonTypeTalkChat, // 语音
    JYJInstrumentViewButtonTypeVedioChat, // 视频
    JYJInstrumentViewButtonTypeCamera // 照相机
};

@class JYJInstrumentView;

@protocol JYJInstrumentViewDelegate <NSObject>

@optional

- (void)instrumentView:(JYJInstrumentView *)instrumentView didClickButton:(JYJInstrumentViewButtonType)buttonType;

@end

@interface JYJInstrumentView : UIView
+ (instancetype)instrumentView;
/** 代理 */
@property (nonatomic, weak) id <JYJInstrumentViewDelegate> delegate;
@end
