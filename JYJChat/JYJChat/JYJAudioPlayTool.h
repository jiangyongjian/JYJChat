//
//  JYJAudioPlayTool.h
//  JYJChat
//
//  Created by JYJ on 16/7/7.
//  Copyright © 2016年 baobeikeji. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "EMSDK.h"
@interface JYJAudioPlayTool : NSObject

+ (void)playWithMessage:(EMMessage *)msg msgLabel:(UILabel *)msgLabel receiver:(BOOL)receiver;

+(void)stop;
@end
