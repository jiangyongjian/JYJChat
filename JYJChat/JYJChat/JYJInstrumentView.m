//
//  JYJInstrumentView.m
//  JYJChat
//
//  Created by JYJ on 16/7/19.
//  Copyright © 2016年 baobeikeji. All rights reserved.
//

#import "JYJInstrumentView.h"

@implementation JYJInstrumentView

+ (instancetype)instrumentView {
    return [[self alloc] init];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addButtonWithIcon:nil hightIcon:nil title:@"图片" tag:JYJInstrumentViewButtonTypePicture];
        [self addButtonWithIcon:nil hightIcon:nil title:@"语音" tag:JYJInstrumentViewButtonTypeTalkChat];
        [self addButtonWithIcon:nil hightIcon:nil title:@"视频" tag:JYJInstrumentViewButtonTypeVedioChat];
    }
    return self;
}

- (UIButton *)addButtonWithIcon:(NSString *)icon hightIcon:(NSString *)hightIcon title:(NSString *)title tag:(JYJInstrumentViewButtonType)tag {
    UIButton *button = [UIButton buttonWithTitle:title titleColor:[UIColor whiteColor] font:[UIFont fontWithTwoLine:18] target:self action:@selector(buttonClick:) backImageName:nil];
    button.tag = tag;
    button.backgroundColor = [UIColor redColor];
    [self addSubview:button];
    return button;
}
/**
 *  监听按钮点击
 */
- (void)buttonClick:(UIButton *)button
{
    if ([self.delegate respondsToSelector:@selector(instrumentView:didClickButton:)]) {
        [self.delegate instrumentView:self didClickButton:(NSUInteger)button.tag];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    NSUInteger count = self.subviews.count;
    NSUInteger cols = 3;
    NSUInteger rows = 2;
    CGFloat buttonMargin = 20;
    CGFloat buttonWith = (self.width - buttonMargin * (cols + 1)) / cols;
    CGFloat buttonHight = (self.height - buttonMargin * (rows + 1)) / rows;
    for (int i = 0; i < count; i++) {
        UIButton *button = self.subviews[i];
        button.x = buttonMargin + (buttonWith + buttonMargin) * (i % cols);
        button.y = buttonMargin + (buttonHight + buttonMargin) * (i / cols);
        button.width = buttonWith;
        button.height = buttonHight;
    }
}

@end
