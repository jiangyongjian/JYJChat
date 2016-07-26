//
//  JYJChatViewController.m
//  JYJChat
//
//  Created by JYJ on 16/6/29.
//  Copyright © 2016年 baobeikeji. All rights reserved.
//

#import "JYJChatViewController.h"
#import "JYJChatCell.h"
#import "EMSDK.h"
#import "EMCDDeviceManager.h"
#import "JYJTimeCell.h"
#import "NSDate+Extension.h"
#import "JYJInstrumentView.h"
#import "JYJRecodeButton.h"
#import "EMSDKFull.h"

@interface JYJChatViewController () <EMChatManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, JYJInstrumentViewDelegate, EMCallManagerDelegate>
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inputToolBarBottomConstraint;
/** 数据源 */
@property (nonatomic, strong) NSMutableArray *dataSources;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

/** 计算高度的cell工具对象 */
@property (nonatomic, strong) JYJChatCell *chatCellTool;
/**  InputToolBar 高度的约束 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inputToolBarHeightConstraint;
/*!
 @property
 @brief 聊天的会话对象
 */
@property (nonatomic, strong) EMConversation *conversation;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (weak, nonatomic) IBOutlet JYJRecodeButton *recordBtn;

/** 当前键盘的高度 */
@property (nonatomic, assign) CGFloat previousTextViewContentHeight;
///** 是否显示PickerController */
//@property (nonatomic, assign, getter=isShowImagePickerController) BOOL showImagePickerController;

////2.获取消息发送时间
//@property (nonatomic, strong) NSDate *currentDate;

/** 工具键盘 */
@property (nonatomic, strong) JYJInstrumentView *instrumentView;
/** 表情键盘 */
@property (nonatomic, strong) UIView *emojiView;

/**  是否正在切换键盘emoji */
@property (nonatomic, assign, getter=isEmojiKeyboard) BOOL emojiKeyboard;
/**  是否正在切换键盘instrument */
@property (nonatomic, assign, getter=isInstrumentKeyboard) BOOL instrumentKeyboard;
/** 是否系统键盘显示 */
@property (nonatomic, assign, getter=isShowingSystemKeyboard) BOOL showingSystemKeyboard;
@property (weak, nonatomic) IBOutlet UIButton *voiceBtn;
@property (weak, nonatomic) IBOutlet UIButton *emojiBtn;
@property (weak, nonatomic) IBOutlet UIButton *instrumentBtn;
@property (weak, nonatomic) IBOutlet UIView *inputToolBar;

/** callSession */
@property (nonatomic, strong) EMCallSession *callSession;
/** 当前的contentOffSet */
@property (nonatomic, assign) CGFloat contentOffsetY;
/** 将要界面即将消失 */
@property (nonatomic, assign) BOOL inputToolBarWillDisappear;

@end

@implementation JYJChatViewController

#pragma mark - 懒加载
- (CGFloat)previousTextViewContentHeight {
    if (_previousTextViewContentHeight == 0) {
        _previousTextViewContentHeight = self.textView.frame.size.height;
    }
    return _previousTextViewContentHeight;
}

-(NSMutableArray *)dataSources{
    if (!_dataSources) {
        _dataSources = [NSMutableArray array];
    }
    
    return _dataSources;
}

- (JYJInstrumentView *)instrumentView {
    if (!_instrumentView) {
        self.instrumentView = [JYJInstrumentView instrumentView];
        self.instrumentView.delegate = self;
        self.instrumentView.x = 0;
        self.instrumentView.y = BXScreenH;
        self.instrumentView.width = BXScreenW;
        self.instrumentView.height = BXInputH;
        self.instrumentView.backgroundColor = [UIColor purpleColor];
#warning TODO 这句话为了强制布局，防止出现动画, 且这句话要放在设置frame的后面
        [self.instrumentView layoutIfNeeded];
        [self.view addSubview:self.instrumentView];
    }
    return _instrumentView;
}

- (UIView *)emojiView {
    if (!_emojiView) {
        self.emojiView = [[UIView alloc] init];
        self.emojiView.backgroundColor = [UIColor greenColor];
        self.emojiView.x = 0;
        self.emojiView.y = BXScreenH;
        self.emojiView.width = BXScreenW;
        self.emojiView.height = BXInputH;
        [self.view addSubview:self.emojiView];
    }
    return _emojiView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.interactivePopGestureRecognizer.delaysTouchesBegan = NO;
    [self.recordBtn addTarget:self action:@selector(beginRecordAction:) forControlEvents:UIControlEventTouchDown];
    [self.recordBtn addTarget:self action:@selector(endRecordAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.recordBtn addTarget:self action:@selector(cancelRecordAction:) forControlEvents:UIControlEventTouchUpOutside];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.tableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    self.title = self.aUsername;
#warning 这里需要根据字体来计算改变位置高度，这里写死，其他情况可以自己调整。
    self.textView.font = [UIFont systemFontOfSize:16];
    self.textView.enablesReturnKeyAutomatically = YES;
    // 计算高度的cell工具对象 赋值
    self.chatCellTool = [self.tableView dequeueReusableCellWithIdentifier:ReceiverCell];
    
    // 加载本地数据库聊天记录（message）
    [self loadLocalChatRecords];
    
    // 设置聊天管理器的代理
    [[EMClient sharedClient].chatManager addDelegate:self delegateQueue:nil];
//    // 添加实时通话代理
//    [[EMClient sharedClient].callManager addDelegate:self delegateQueue:nil];
    
    // 1.监听键盘弹出，把inputToolBar（输入工具条）往上移
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kbWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    // 2.监听键盘退出，inputToolBar回复原位
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kbWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    // 4.把消息现在在顶部
    [self scrollToBottom:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.inputToolBarWillDisappear = YES;
}

#pragma mark - 获取本地聊天数据
- (void)loadLocalChatRecords {
    //假设在数组的第一位置添加时间
//    [self.dataSources addObject:@"13:14"];
    // 要获取本地聊天记录使用 会话对象
    
    NSString *conversationStr = self.isGroup ? self.group.groupId : self.aUsername;
    EMConversationType type = self.isGroup ? EMConversationTypeChat : EMConversationTypeGroupChat;
    EMConversation *conversation = [[EMClient sharedClient].chatManager getConversation:conversationStr type:type createIfNotExist:YES];
    self.conversation = conversation;
    BXLog(@"%@", self.conversation);
    // 加载与当前聊天用户所有聊天记录
    NSArray *moreMessages = [conversation loadMoreMessagesFromId:nil limit:1000 direction:EMMessageSearchDirectionUp];
//    NSLog(@"%@", moreMessages);

//    for (id obj in moreMessages) {
//        NSLog(@"%@ -- %@", obj, [obj class]);
//    }
    
    // 添加到数据源
    for (EMMessage *msgObj in moreMessages) {
        [self addDataSourcesWithMessage:msgObj];
    }
//    [self.dataSources addObjectsFromArray:moreMessages];
}

#pragma mark 键盘显示时会触发的方法
-(void)kbWillShow:(NSNotification *)noti {
//    if (self.showImagePickerController) return;
    self.showingSystemKeyboard = YES;
    self.instrumentBtn.selected = NO;
    self.emojiBtn.selected = NO;
//    // 如果正在切换键盘，就不要执行后面的代码
//    if (self.isChangingKeyboard) return;
    //1.获取键盘高度
    //1.1获取键盘结束时候的位置
    CGRect kbEndFrame = [noti.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat kbHeight = kbEndFrame.size.height;
    
    CGRect beginRect = [[noti.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    
    CGRect endRect = [[noti.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    NSLog(@"%f", kbHeight);
    BXLog(@"%@    ----   %@,    %f  xxx %f ",NSStringFromCGRect(beginRect), NSStringFromCGRect(endRect), beginRect.size.height, beginRect.origin.y - endRect.origin.y);
    // 第三方键盘回调三次问题，监听仅执行最后一次
    
    if(!(beginRect.size.height > 0 && ( fabs(beginRect.origin.y - endRect.origin.y) > 0))) return;
    
    CGFloat animationDuration = [[noti.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    BXLog(@"%f........", animationDuration);
    // 2.更改inputToolBar 底部约束
    self.inputToolBarBottomConstraint.constant = kbHeight;
    // 添加动画
    if (self.emojiKeyboard) { // 当前展示的是表情键盘
        [UIView animateWithDuration:animationDuration animations:^{
            self.emojiView.y = BXScreenH - kbHeight;
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            self.emojiView.y = BXScreenH;
            self.instrumentView.y = BXScreenH - kbHeight;
            [self.emojiView removeFromSuperview];
        }];
    
    } else if (self.instrumentKeyboard) { // 当前展示的是工具
        [UIView animateWithDuration:animationDuration animations:^{
            self.instrumentView.y = BXScreenH - kbHeight;
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            [self.instrumentView removeFromSuperview];
        }];
    } else {
        [UIView animateWithDuration:animationDuration animations:^{
           [self.view layoutIfNeeded];
        }];
    }
    // 4.把消息现在在顶部
    [self scrollToBottom:NO];
}

#pragma mark 键盘退出时会触发的方法
-(void)kbWillHide:(NSNotification *)noti{
//    if (self.showImagePickerController) return;
//    if (self.isChangingKeyboard) return;
    self.showingSystemKeyboard = NO;
    if (self.emojiBtn.selected || self.instrumentBtn.selected || self.inputToolBarWillDisappear) return;
    
    //inputToolbar恢复原位
    self.inputToolBarBottomConstraint.constant = 0;
    // 添加动画
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    }];
    self.instrumentBtn.selected = NO;
    self.emojiBtn.selected = NO;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    //移除消息回调
    [[EMClient sharedClient].chatManager removeDelegate:self];
    [[EMClient sharedClient].callManager removeDelegate:self];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (scrollView == self.textView) return;
    
    if (self.showingSystemKeyboard) {
        [self.instrumentView removeFromSuperview];
        [self.emojiView removeFromSuperview];
    }
    [self.view endEditing:YES];
    //inputToolbar恢复原位
    self.inputToolBarBottomConstraint.constant = 0;
    // 添加动画
    [UIView animateWithDuration:0.25 animations:^{
        if (self.showingSystemKeyboard || self.emojiBtn.selected || self.instrumentBtn.selected) {
            self.instrumentView.y = BXScreenH;
            self.emojiView.y = BXScreenH;
        }
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self.instrumentView removeFromSuperview];
        [self.emojiView removeFromSuperview];
    }];
    self.instrumentBtn.selected = NO;
    self.emojiBtn.selected = NO;

}


#pragma mark - toolBar上按钮点击
/**
 *  点击了工具
 */
- (IBAction)instrumentBtnClick:(UIButton *)instrumentBtn {
    [self.emojiView removeFromSuperview];
    self.emojiKeyboard = NO;
    UIView *instrumentView = self.instrumentView;
//    [self.view addSubview:instrumentView];
    if (self.emojiBtn.selected) { // 表情键盘有选中
        self.instrumentBtn.selected = YES;
        self.instrumentKeyboard = YES;
        if (!self.showingSystemKeyboard) {
            self.instrumentView.y = BXScreenH;
        }

        self.emojiView.y = BXScreenH;
        self.emojiBtn.selected = NO;
        [self.view addSubview:instrumentView];
        // 2.更改inputToolBar 底部约束
        self.inputToolBarBottomConstraint.constant = BXInputH;
        // 添加动画
        [UIView animateWithDuration:0.25 animations:^{
            instrumentView.y = BXScreenH - BXInputH;
            [self.view layoutIfNeeded];
        }];

    } else { // 表情键盘没有选择
        instrumentBtn.selected = !instrumentBtn.selected;
        if (instrumentBtn.selected) {
            // 让vioce声音按钮,取消选择,隐藏录音按钮
            [self setVioceRecordStates];
            
            if (!self.showingSystemKeyboard) {
                self.instrumentView.y = BXScreenH;
            }
            self.recordBtn.selected = NO;
            [self.textView resignFirstResponder];
            self.instrumentKeyboard = YES;
            [self.view addSubview:instrumentView];
            // 2.更改inputToolBar 底部约束
            self.inputToolBarBottomConstraint.constant = BXInputH;
            // 添加动画
            [UIView animateWithDuration:0.25 animations:^{
                instrumentView.y = BXScreenH - BXInputH;
                [self.view layoutIfNeeded];
                // 4.把消息现在在顶部
                [self scrollToBottom:NO];
            }];
      
        } else {
            self.instrumentKeyboard = YES;
            [self.textView becomeFirstResponder];
        }
    }
}

/**
 * 点击了表情
 */
- (IBAction)emojiBtnClick:(UIButton *)emojiBtn {
    //    self.instrumentBtn.selected = NO;
    [self.instrumentView removeFromSuperview];
    self.instrumentKeyboard = NO;
    UIView *emojiView = self.emojiView;
//    [self.view addSubview:emojiView];
    if (self.instrumentBtn.selected) { // 工具+有选中
        self.emojiBtn.selected = YES;
        self.emojiKeyboard= YES;
        if (!self.showingSystemKeyboard) {
            self.instrumentView.y = BXScreenH;
        }
        
//        self.instrumentView.y = BXScreenH;
        self.instrumentBtn.selected = NO;
        [self.view addSubview:emojiView];
        // 2.更改inputToolBar 底部约束
        self.inputToolBarBottomConstraint.constant = BXInputH;
        // 添加动画
        [UIView animateWithDuration:0.25 animations:^{
            emojiView.y = BXScreenH - BXInputH;
            [self.view layoutIfNeeded];
        }];
        
    } else { // 工具+没有选中
        emojiBtn.selected = !emojiBtn.selected;
        if (emojiBtn.selected) {
            // 让vioce声音按钮,取消选择,隐藏录音按钮
            [self setVioceRecordStates];
            if (!self.showingSystemKeyboard) {
                self.emojiView.y = BXScreenH;
            }
            
            [self.textView resignFirstResponder];
            self.emojiKeyboard = YES;
            [self.view addSubview:emojiView];
            // 2.更改inputToolBar 底部约束
            self.inputToolBarBottomConstraint.constant = BXInputH;
            
            // 添加动画
            [UIView animateWithDuration:0.25 animations:^{
                emojiView.y = BXScreenH - BXInputH;
                [self.view layoutIfNeeded];
                // 4.把消息现在在顶部
                [self scrollToBottom:NO];
            }];
        } else {
            self.emojiKeyboard = YES;
            [self.textView becomeFirstResponder];
        }
    }
}
/**
 *  让vioce声音按钮,取消选择,隐藏录音按钮
 */
- (void)setVioceRecordStates {
    self.voiceBtn.selected = NO;
    self.recordBtn.hidden = YES;
    self.textView.hidden = NO;
    // 恢复InputToolBar高度
    [self textViewDidChange:self.textView];
}


#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSources.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 时间cell的高度固定
    if ([self.dataSources[indexPath.row] isKindOfClass:[NSString class]]) {
        return 18;
    }
    
    // 设置label的数据
#warning 计算高度与前，一定要给messageLabel.text赋值
    // 1.获取消息模型
    EMMessage *msg = self.dataSources[indexPath.row];

    self.chatCellTool.message = msg;
    return [self.chatCellTool cellHeight];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 判断数据源类型
    if ([self.dataSources[indexPath.row] isKindOfClass:[NSString class]]) { // 显示时间cell
        JYJTimeCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TimeCell"];
        cell.timeLabel.text = self.dataSources[indexPath.row];
        return cell;
    }
    
    // 1.先获取消息模型
    EMMessage *message = self.dataSources[indexPath.row];
    
    //    EMMessage
    /* from:jyj to:jyj006 发送方（自己）
     * from:jyj006 to:jyj 接收方 （好友）
     */
    
    JYJChatCell *cell = nil;
    if (message.direction == EMMessageDirectionSend) { // 发送方的cell
        cell = [tableView dequeueReusableCellWithIdentifier:SenderCell];
    } else { // 接收发方的cell
        cell = [tableView dequeueReusableCellWithIdentifier:ReceiverCell];
    }
    // 显示内容
    cell.message = message;
    return cell;
}

#pragma mark - UITextView代理
-(void)textViewDidChange:(UITextView *)textView {
    BXLog(@"%@", textView.text);
    // 1.计算textView的高度
    CGFloat textViewH = 0;
    CGFloat minHeight = 33 + 3; // textView最小的高度
    CGFloat maxHeight = 83 + 3 +10; // textView最大的高度

    // 获取contentSize 的高度
    CGFloat contentHeight = textView.contentSize.height;
    
    if (contentHeight < minHeight) {
        textViewH = minHeight;
        [textView setContentInset:UIEdgeInsetsZero];
    } else if (contentHeight > maxHeight) {
        textViewH = maxHeight + 4.5;
        [textView setContentInset:UIEdgeInsetsMake(-5, 0, -3.5, 0)];
    } else {
        if (contentHeight ==  minHeight) {
            [textView setContentInset:UIEdgeInsetsZero];
            textViewH = minHeight;
        } else {
            textViewH = contentHeight - 8;
            [textView setContentInset:UIEdgeInsetsMake(-4.5, 0, -4.5, 0)];
        }
    }
    // 2.监听send事件--判断最后一个字符串是不是换行符
    if ([textView.text hasSuffix:@"\n"]) {
        [self sendText:textView.text];
        // 清空textView的文字
        textView.text = nil;
        [textView setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];
        
        // 发送时，textViewH的高度为33
        textViewH = minHeight;
    }
    
    // 3.调整整个InputToolBar 的高度
    self.inputToolBarHeightConstraint.constant = 6 + 7 + textViewH;
    CGFloat changeH = textViewH - self.previousTextViewContentHeight;
    if (changeH != 0) {
        
        // 加个动画
        [UIView animateWithDuration:0.25 animations:^{
            [self.view layoutIfNeeded];
            if (textView.text.length) {
                [self scrollToBottom:NO];
            }
            // 4.记光标回到原位
#warning 技巧
            // 下面这几行代码需要写在[self.view layoutIfNeeded]后面，不然系统会自动调整为位置
            if (contentHeight < maxHeight) {
                [textView setContentOffset:CGPointZero animated:YES];
                [textView scrollRangeToVisible:textView.selectedRange];
            }
        }];
        self.previousTextViewContentHeight = textViewH;
    }
   
    if (contentHeight > maxHeight) {
        [UIView animateWithDuration:0.2 animations:^{
            if (self.contentOffsetY) {
                if (textView.selectedRange.location != textView.text.length && textView.contentOffset.y != self.contentOffsetY) return;
            }
#warning 现在还是不是很明白3.5为什么要跟上面的3.5对应
            [textView setContentOffset:CGPointMake(0.0, textView.contentSize.height - textView.frame.size.height - 3.5)];
            self.contentOffsetY = textView.contentOffset.y;
        }];
        [textView scrollRangeToVisible:textView.selectedRange];
    }
    
}

#pragma mark - 发送文本消息
- (void)sendText:(NSString *)text {
    // 消息 = 消息头 + 消息体
#warning 每一种类型对象的不同的消息体
//    EMTextMessageBody 文本消息体
//    EMVoiceMessageBody 录音消息体
//    EMVideoMessageBody 视频消息体
//    EMLocationMessageBody 位置消息体
//    EMImageMessageBody 图片消息体
    NSString *text1 = [text substringToIndex:text.length - 1];
    // 1.创建一个文本消息体
    EMTextMessageBody *textBody = [[EMTextMessageBody alloc] initWithText:text1];
    
    [self sendMessage:textBody];
}

#pragma mark 发送语音消息
- (void)sendVoice:(NSString *)recordPath duration:(NSInteger)aDuration {
    // 1.构造一个 语音消息体
    EMVoiceMessageBody *body = [[EMVoiceMessageBody alloc] initWithLocalPath:recordPath displayName:@"[语音]"];
    body.duration = (int)aDuration;
    
    [self sendMessage:body];
}

#pragma mark - 发送图片
- (void)sendImg:(UIImage *)selectedImg {
    NSLog(@"%@", selectedImg);
    NSData *data = UIImageJPEGRepresentation(selectedImg, 1);
    // 1.构造图片消息体
    EMImageMessageBody *imgBody = [[EMImageMessageBody alloc] initWithData:data displayName:@"[图片]"];
    NSLog(@"%@", imgBody);
    [self sendMessage:imgBody];
}

- (void)sendMessage:(EMMessageBody *)body {
    NSString *from = [[EMClient sharedClient] currentUsername];
    // 2.构造一个消息对象
    NSString *reciver = self.isGroup ? self.group.groupId : self.aUsername;
    
    EMMessage *msgObj = [[EMMessage alloc] initWithConversationID:reciver from:from to:reciver body:body ext:nil];
    //聊天的类型 单聊
    msgObj.chatType = self.isGroup ? EMChatTypeGroupChat : EMChatTypeChat;
    
    [self addMessageToDataSource:msgObj progress:nil];
    
    __weak typeof(self) weakSelf = self;
    // 3.发送
    [[EMClient sharedClient].chatManager asyncSendMessage:msgObj progress:nil completion:^(EMMessage *message, EMError *error) {
        if (!error) {
            NSLog(@"图片发送成功");
            [weakSelf.tableView reloadData];
        }else{
            NSLog(@"图片发送失败");
        }
    }];
//    // 3.把消息添加到数据源，然后刷新表格
//    [self.dataSources addObject:msgObj];
//    [self.tableView reloadData];
//    
//    // 4.把消息显示在顶部
//    [self scrollToBottom:YES];
}

-(void)addMessageToDataSource:(EMMessage *)msgObj
                     progress:(id)progress
{
    // 3.把消息添加到数据源，然后刷新表格
//    [self.dataSources addObject:msgObj];
    [self addDataSourcesWithMessage:msgObj];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
//            [weakSelf.dataArray addObjectsFromArray:messages];
//            // 3.把消息添加到数据源，然后刷新表格
//            [weakSelf.dataSources addObject:msgObj];
//            __strong typeof(weakSelf) strongSelf = weakSelf;
            [weakSelf.tableView reloadData];
//            [weakSelf scrollToBottom:YES];
            [weakSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[weakSelf.dataSources count] - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        });
    });
}


/**
 *  让tableView滚动到最底部
 */
- (void)scrollToBottom:(BOOL)animated {
    // 1.获取最后一行
    if (self.dataSources.count == 0) {
        return;
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.dataSources.count - 1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
}

#pragma mark - 监听好友回复消息
- (void)didReceiveMessages:(NSArray *)aMessages {
#warning TODO from 一点等于当前聊天用户才能刷新数据
    for (EMMessage *message in aMessages) {
        if ([self.conversation.conversationId isEqualToString:message.conversationId]) {
            
            EMMessageBody *msgBody = message.body;
            if (msgBody.type == EMMessageBodyTypeImage) {
                // 得到一个图片消息body
                EMImageMessageBody *body = ((EMImageMessageBody *)msgBody);
                //            NSLog(@"大图remote路径 -- %@"   ,body.remotePath);
                NSLog(@"大图local路径 -- %@"    ,body.localPath); // // 需要使用sdk提供的下载方法后才会存在
                NSLog(@"大图的secret -- %@"    ,body.secretKey);
                NSLog(@"大图的W -- %f ,大图的H -- %f",body.size.width,body.size.height);
                NSLog(@"大图的下载状态 -- %zd",body.downloadStatus);
                
                
                // 缩略图sdk会自动下载
                NSLog(@"小图remote路径 -- %@"   ,body.thumbnailRemotePath);
                NSLog(@"小图local路径 -- %@"    ,body.thumbnailLocalPath);
                NSLog(@"小图的secret -- %@"    ,body.thumbnailSecretKey);
                NSLog(@"小图的W -- %f ,大图的H -- %f",body.thumbnailSize.width,body.thumbnailSize.height);
                NSLog(@"小图的下载状态 -- %zd",body.thumbnailDownloadStatus);
                
            }

        
        // 1.把接收的消息添加到数据源
//        [self.dataSources addObject:message];
        [self addDataSourcesWithMessage:message];
       
        // 2.刷新表格
        [self.tableView reloadData];
        
        // 3.显示数据带底部
        [self scrollToBottom:YES];
        }
    }
}
#pragma mark - Action
- (IBAction)voiceAction:(UIButton *)sender {
    // 1.显示录音按钮
    sender.selected = !sender.selected;
    self.textView.hidden = self.recordBtn.hidden;
    self.recordBtn.hidden = !self.recordBtn.hidden;
    self.previousTextViewContentHeight = 49;
    // 2.退出或者显示键盘
    if (self.recordBtn.hidden == NO) { // 录音按钮显示
        self.inputToolBarHeightConstraint.constant = 49;
        // 隐藏键盘
        [self scrollViewWillBeginDragging:nil];
    } else {
        // 不录音的时候，键盘显示
        [self.textView becomeFirstResponder];
        
        // 恢复InputToolBar高度
        [self textViewDidChange:self.textView];
    }
}

#pragma mark 按钮点下去开始录音
- (void)beginRecordAction:(JYJRecodeButton *)sender {
    sender.selected = YES;
    // 文件名以时间命名
    int x = arc4random() % 100000;
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    NSString *fileName = [NSString  stringWithFormat:@"%d%d", (int)time, x];
    NSLog(@"按钮点下去开始录音");
    
    [[EMCDDeviceManager sharedInstance] asyncStartRecordingWithFileName:fileName completion:^(NSError *error) {
        if (!error) {
            NSLog(@"开始录音成功");
        }
    }];
}

#pragma mark 手指从按钮范围内松开结束录音
- (void)endRecordAction:(JYJRecodeButton *)sender {
    sender.selected = NO;
    NSLog(@"手指从按钮松开结束录音");
    __weak typeof(self) weakSelf = self;
    [[EMCDDeviceManager sharedInstance] asyncStopRecordingWithCompletion:^(NSString *recordPath, NSInteger aDuration, NSError *error) {
        if (!error) {
            NSLog(@"录音成功");
            NSLog(@"%@",recordPath);
            // 发送语音给服务器
            [weakSelf sendVoice:recordPath duration: aDuration];
            
        } else{
            NSLog(@"== %@",error);
            
        }
    }];
}
#pragma mark 手指从按钮外面松开取消录音
- (void)cancelRecordAction:(JYJRecodeButton *)sender {
    sender.selected = NO;
    [[EMCDDeviceManager sharedInstance] cancelCurrentRecording];
}

#pragma mark - JYJInstrumentViewDelegate
- (void)instrumentView:(JYJInstrumentView *)instrumentView didClickButton:(JYJInstrumentViewButtonType)buttonType {
    switch (buttonType) {
        case JYJInstrumentViewButtonTypePicture: // 相册
            [self openAlbum];
            break;
        case JYJInstrumentViewButtonTypeTalkChat: // 语音通话
            [self talkChat];
            break;
        case JYJInstrumentViewButtonTypeVedioChat: // 视频聊天
            [self vedioChat];
            break;
        default:
            break;
    }
}
/**
 *  打开相册
 */
- (void)openAlbum {
    [self openImagePicherController:UIImagePickerControllerSourceTypePhotoLibrary];
}


- (void)openImagePicherController:(UIImagePickerControllerSourceType)type {
    // 显示图片选择的控制器
    UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
    
    // 设置源
    imgPicker.sourceType = type;
    imgPicker.delegate = self;
    //    self.showImagePickerController = YES;
    [self presentViewController:imgPicker animated:YES completion:nil];
}
#pragma mark - UIImagePickerControllerDelegate
/** 用户选中图片的回调 */
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    // 1.获取用户选中的图片
    UIImage *selectedImg = info[UIImagePickerControllerOriginalImage];
    
    // 2.发送图片
    [self sendImg:selectedImg];
    
    // 退出当前图片选择控制器
    [self dismissViewControllerAnimated:YES completion:nil];
//    self.showImagePickerController = NO;
}

#pragma mark - 实时通话
- (void)talkChat {
    // 实时通话的类 ICallManagerCall
//    EMCallSession *callSession = [[EMClient sharedClient].callManager makeVoiceCall:self.aUsername error:nil];
//    self.callSession = callSession;
    // 发出talk的通知
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[BXConversationId] = self.conversation.conversationId;
    dict[BXConversationType] = @"0";
    [BXNoteCenter postNotificationName:BXNotificationCall object:nil userInfo:dict];
}



- (void)vedioChat {
    // 实时通话的类 ICallManagerCall
//    EMCallSession *callSession = [[EMClient sharedClient].callManager makeVideoCall:self.aUsername error:nil];
//    self.callSession = callSession;
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[BXConversationId] = self.conversation.conversationId;
    dict[BXConversationType] = @"1";
    [BXNoteCenter postNotificationName:BXNotificationCall object:nil userInfo:dict];
}



- (void)addDataSourcesWithMessage:(EMMessage *)msg {
    // 1.判断EMMessage对象前面是否要加 "时间"
    NSDate *currentDate = 0;
    if (self.dataSources) {
        // 取出最后一个EMMessage对象
        EMMessage *msg = [self.dataSources lastObject];
        //2.获取消息发送时间
        NSDate *msgDate = [NSDate dateWithTimeIntervalSince1970:msg.timestamp/1000.0];
        currentDate = msgDate;
    }
    
    //2.获取消息发送时间
    NSDate *msgDate = [NSDate dateWithTimeIntervalSince1970:msg.timestamp /1000.0];
    NSString *timeStr = [msgDate ff_dateDescription2];
    NSInteger interval = ABS((NSInteger)[msgDate timeIntervalSinceDate:currentDate]);
    
    NSLog(@"%@", currentDate);
    if (interval > 60) {
        [self.dataSources addObject:timeStr];
    }
    // 2.再加EMMessage
    [self.dataSources addObject:msg];
    
    // 3.设置消息为已读
    [self.conversation markMessageAsReadWithId:msg.messageId];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
