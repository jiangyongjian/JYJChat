//
//  JYJChatCell.h
//  JYJChat
//
//  Created by JYJ on 16/6/29.
//  Copyright © 2016年 baobeikeji. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EMSDK.h"

static NSString *ReceiverCell = @"ReceiverCell";
static NSString *SenderCell = @"SenderCell";

@interface JYJChatCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;

/** 消息模型 */
@property (nonatomic, strong) EMMessage *message;
- (CGFloat)cellHeight;
@end
