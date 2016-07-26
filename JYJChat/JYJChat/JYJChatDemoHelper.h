//
//  JYJChatDemoHelper.h
//  JYJChat
//
//  Created by JYJ on 16/7/22.
//  Copyright © 2016年 baobeikeji. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EMSDKFull.h"
@class BXTabBarController, JYJConversationViewController;
@interface JYJChatDemoHelper : NSObject

/** tabBarController */
@property (nonatomic, weak) BXTabBarController *mainTabBarVC;
@property (nonatomic, weak) JYJConversationViewController *conversationListVC;


/** 挂断 */
- (void)hangupCallWithReason:(EMCallEndReason)aReason;

/** 同意接听 */
- (void)answerCall;

/** 加载会话 */
- (void)asyncConversationFromDB;

+ (instancetype)shareHelper;
@end
