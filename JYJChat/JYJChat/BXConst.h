//
//  BXConst.h
//  JYJChat
//
//  Created by JYJ on 16/7/19.
//  Copyright © 2016年 baobeikeji. All rights reserved.
//

#define BXInputH (BXScreenW > 375 ? 210 : 200)

///** 自定义键盘的高度 */
//UIKIT_EXTERN CGFloat const BXInputH;

/** BXNotificationCall发起通话的通知 */
UIKIT_EXTERN NSString *const BXNotificationCall;
/** BXNotification字典中的conversationId key */
UIKIT_EXTERN NSString *const BXConversationId;
/** BXNotification字典中的BXConversationType key */
UIKIT_EXTERN NSString *const BXConversationType;