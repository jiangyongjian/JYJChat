//
//  JYJConversationViewController.m
//  JYJChat
//
//  Created by JYJ on 16/6/28.
//  Copyright © 2016年 baobeikeji. All rights reserved.
//

#import "JYJConversationViewController.h"
#import "EMSDK.h"
#import "JYJChatViewController.h"

@interface JYJConversationViewController () <EMClientDelegate, EMContactManagerDelegate, EMChatManagerDelegate, UIAlertViewDelegate>

/** 好友的名称 */
@property (nonatomic, copy) NSString *buddyUsername;

/** 会话数组 */
@property (nonatomic, strong) NSMutableArray *conversations;
@end

@implementation JYJConversationViewController

- (NSMutableArray *)conversations {
    if (!_conversations) {
        self.conversations = [NSMutableArray array];
    }
    return _conversations;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [JYJChatDemoHelper shareHelper].conversationListVC = self;
    // 设置代理
    [[EMClient sharedClient] addDelegate:self delegateQueue:nil];
    
    //注册好友回调
    [[EMClient sharedClient].contactManager addDelegate:self delegateQueue:nil];
    
    [[EMClient sharedClient].chatManager addDelegate:self delegateQueue:nil];
    
    // 加载数据
    [self loadConversation];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadConversation];
}

- (void)loadConversation {
    [self.conversations removeAllObjects];
    // 从本地获取
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *array = [[EMClient sharedClient].chatManager loadAllConversationsFromDB];
        [array enumerateObjectsUsingBlock:^(EMConversation *conversation, NSUInteger idx, BOOL *stop){
            if(conversation.latestMessage == nil){
                [[EMClient sharedClient].chatManager deleteConversation:conversation.conversationId deleteMessages:NO];
            }
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *conversations = [[EMClient sharedClient].chatManager getAllConversations];
            NSArray *sorted = [conversations sortedArrayUsingComparator:
                               ^(EMConversation *obj1, EMConversation* obj2){
                                   EMMessage *message1 = [obj1 latestMessage];
                                   EMMessage *message2 = [obj2 latestMessage];
                                   if(message1.timestamp > message2.timestamp) {
                                       return(NSComparisonResult)NSOrderedAscending;
                                   }else {
                                       return(NSComparisonResult)NSOrderedDescending;
                                   }
                               }];
            weakself.conversations = [NSMutableArray arrayWithArray:sorted];
            [weakself.tableView reloadData];
            // 设置消息未读数
            [weakself setupUnreadMessageCount];
        });
    });
    
    
    
}

// 统计未读消息数
- (void)setupUnreadMessageCount {
    NSInteger unreadCount = 0;
    for (EMConversation *conversation in self.conversations) {
        unreadCount += conversation.unreadMessagesCount;
    }
    BXLog(@"%zd", unreadCount);
    if (unreadCount > 0) {
        self.navigationController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%zd", unreadCount];
    } else {
        self.navigationController.tabBarItem.badgeValue = nil;
    }
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:unreadCount];
}



#pragma mark - chatManger代理方法
// 1.监听网络状态
- (void)didConnectionStateChanged:(EMConnectionState)aConnectionState {
//    EMConnectionConnected = 0,  /* 已连接 */
//    EMConnectionDisconnected,   /* 未连接 */
    if (aConnectionState == EMConnectionDisconnected) {
        NSLog(@"网诺断开, 未连接....");
    } else {
        NSLog(@"网络通了....");
    }
}

#pragma mark - 好友添加请求同意
- (void)didReceiveFriendInvitationFromUsername:(NSString *)aUsername message:(NSString *)aMessage {
    NSLog(@"接收到%@的好友请求", aUsername);
    
    // 赋值
    self.buddyUsername = aUsername;
    
    // 对话框
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"好友添加请求" message:aMessage delegate:self cancelButtonTitle:@"拒绝" otherButtonTitles:@"同意", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) { // 拒绝好友请求
        EMError *error = [[EMClient sharedClient].contactManager declineInvitationForUsername:self.buddyUsername];
        if (!error) {
            NSLog(@"发送拒绝成功");
        }
    } else { // 同意好友请求
        EMError *error = [[EMClient sharedClient].contactManager acceptInvitationForUsername:self.buddyUsername];
        if (!error) {
            NSLog(@"发送同意成功");
        }
    }
}
#pragma mark - 好友请求被拒绝
/*!
 @method
 @brief 用户A发送加用户B为好友的申请，用户B拒绝后，用户A会收到这个回调
 */
- (void)didReceiveDeclinedFromUsername:(NSString *)aUsername {
    // 提醒用户，好友请求被同意
    NSString *message = [NSString stringWithFormat:@"%@ 拒绝了你的好友请求",aUsername];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"好友添加消息" message:message delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
    [alert show];
}


- (void)dealloc {
    //移除好友回调
    [[EMClient sharedClient].contactManager removeDelegate:self];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.conversations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ID = @"heh";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
    }
    EMConversation *conver = self.conversations[indexPath.row];
    EMMessage *message = conver.latestMessage;
    
    NSString *textStr = nil;
    id msgBody = message.body;
    if ([msgBody isKindOfClass:[EMTextMessageBody class]]) {
        EMTextMessageBody *textBody = msgBody;
        textStr = textBody.text;
    } else if ([msgBody isKindOfClass:[EMImageMessageBody class]]) {
        EMImageMessageBody *imgBody = msgBody;
        textStr = imgBody.displayName;
    } else if ([msgBody isKindOfClass:[EMVoiceMessageBody class]]) {
        EMVoiceMessageBody *voiceBody = msgBody;
        textStr = voiceBody.displayName;
    } else{
        textStr = @"未知消息类型";
    }
    
    // 显示名字和未读数
    NSString *chatter = nil;
    if (conver.type == EMConversationTypeGroupChat) {
        EMGroup *group = [EMGroup groupWithId:conver.conversationId];
        chatter = group.subject;
    } else {
        chatter = conver.conversationId;
    }
    
    NSString *str = [NSString stringWithFormat:@"%@ -- %zd", conver.conversationId, [conver unreadMessagesCount]];
    cell.textLabel.text = str;
    cell.detailTextLabel.text = textStr;
    cell.imageView.image = [UIImage imageNamed:@"chatListCellHead"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    EMConversation *conversation = self.conversations[indexPath.row];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    JYJChatViewController *chatVc = [storyboard instantiateViewControllerWithIdentifier:@"JYJChatViewController"];
    chatVc.hidesBottomBarWhenPushed = YES;
    if (conversation.type == EMConversationTypeGroupChat) {
        chatVc.isGroup = YES;
        EMGroup *group = [EMGroup groupWithId:conversation.conversationId];
        chatVc.group = group;
    } else {
        chatVc.isGroup = NO;
        chatVc.aUsername = conversation.conversationId;
    }
    [self.navigationController pushViewController:chatVc animated:YES];

    [self.tableView reloadData];

}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
