//
//  JYJChatViewController.h
//  JYJChat
//
//  Created by JYJ on 16/6/29.
//  Copyright © 2016年 baobeikeji. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface JYJChatViewController : UIViewController

- (instancetype)initWithIsGroup:(BOOL)isGroup;

/** 群组信息 */
@property (nonatomic, strong) EMGroup *group;

/** 好友名字 */
@property (nonatomic, copy) NSString *aUsername;
/** 是否是群组 */
@property (nonatomic, assign) BOOL isGroup;
@end
