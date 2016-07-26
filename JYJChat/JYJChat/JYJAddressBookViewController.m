//
//  JYJAddressBookViewController.m
//  JYJChat
//
//  Created by JYJ on 16/6/29.
//  Copyright © 2016年 baobeikeji. All rights reserved.
//

#import "JYJAddressBookViewController.h"
#import "EMSDK.h"
#import "JYJChatViewController.h"
#import "JYJGroupController.h"

@interface JYJAddressBookViewController () <EMChatManagerDelegate, EMContactManagerDelegate>
/** 好友列表数据源 */
@property (nonatomic, strong) NSMutableArray *buddyList;
@end

@implementation JYJAddressBookViewController

//- (void)viewWillAppear:(BOOL)animated {
//    [super viewWillAppear:animated];
//    self.tabBarController.tabBar.hidden = NO;
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    // 添加聊天管理的代理
    [[EMClient sharedClient].chatManager addDelegate:self delegateQueue:nil];
    
    // 注册好友回调
    [[EMClient sharedClient].contactManager addDelegate:self delegateQueue:nil];
    
    // 获取好友列表数据
    /** 注意
     *  1.好友列表buddyList需要在自动登录成功后才有值
     *  2.buddyList 的数据是从本地数据库获取的
     */
    [self setupData];
   
    // 群组按钮
    UIButton *groupBtn = [[UIButton alloc] init];
    groupBtn.frame = CGRectMake(0, 0, BXScreenW, 44);
    [groupBtn setTitle:@"群组" forState:UIControlStateNormal];
    [groupBtn addTarget:self action:@selector(groupBtnClick) forControlEvents:UIControlEventTouchUpInside];
    groupBtn.backgroundColor = [UIColor lightGrayColor];
    self.tableView.tableHeaderView = groupBtn;
    
}

- (void)groupBtnClick {
    JYJGroupController *groupVc = [[JYJGroupController alloc] init];
    groupVc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:groupVc animated:YES];
}

#pragma mark - data

- (void)setupData
{
    NSArray *contactsSource = [[EMClient sharedClient].contactManager getContactsFromDB];
    self.buddyList = [NSMutableArray arrayWithArray:contactsSource];
    
    NSString *loginUsername = [[EMClient sharedClient] currentUsername];
    if (loginUsername && loginUsername.length > 0) {
        [self.buddyList addObject:loginUsername];
    }
    
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        EMError *error = nil;
        NSArray *contactsSource = [[EMClient sharedClient].contactManager getContactsFromServerWithError:&error];
        if (!error) {
            [[EMClient sharedClient].contactManager getBlackListFromServerWithError:&error];
            if (!error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself.buddyList removeAllObjects];
                    
                    for (NSInteger i = 0; i < contactsSource.count; i++) {
                        NSString *username = [contactsSource objectAtIndex:i];
                        [weakself.buddyList addObject:username];
                    }
                    
                    NSString *loginUsername = [[EMClient sharedClient] currentUsername];
                    if (loginUsername && loginUsername.length > 0) {

                        [weakself.buddyList addObject:loginUsername];
                    }
                    [weakself.tableView reloadData];
                });
            }
        }
    });
}

- (void)reloadDataSource
{
    [self.buddyList removeAllObjects];
    
    NSArray *buddyList = [[EMClient sharedClient].contactManager getContactsFromDB];
    
    for (NSString *buddy in buddyList) {
        [self.buddyList addObject:buddy];
    }
    
    NSString *loginUsername = [[EMClient sharedClient] currentUsername];
    if (loginUsername && loginUsername.length > 0) {
        [self.buddyList addObject:loginUsername];
    }
    [self.tableView reloadData];
}


#pragma mark - 好友申请处理结果回调
- (void)didReceiveAddedFromUsername:(NSString *)aUsername {
    // 把新的好友显示到表格
//    self.buddyList = [[EMClient sharedClient].contactManager getContactsFromDB];
    [self reloadDataSource];
    NSLog(@"%@", self.buddyList);
    [self.tableView reloadData];
}


- (void)dealloc {
    // 移除好友回调
    [[EMClient sharedClient].contactManager removeDelegate:self];
}

/*!
 @method
 @brief 用户A发送加用户B为好友的申请，用户B拒绝后，用户A会收到这个回调
 */
- (void)didReceiveDeclinedFromUsername:(NSString *)aUsername {

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.buddyList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *ID = @"BuddyCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    
    
    // 1.显示头像
    cell.imageView.image = [UIImage imageNamed:@"chatListCellHead"];
    
    // 2.显示名称
    cell.textLabel.text = self.buddyList[indexPath.row];
    
    return cell;
}

#pragma mark  实现下面的方法就会出现表格的Delete按钮
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // 获取移除好友的名字
        NSString *deleteUserName = self.buddyList[indexPath.row];
        
        // 删除好友
        [[EMClient sharedClient].contactManager deleteContact:deleteUserName];
        [self.tableView reloadData];
    }
}

- (void)didReceiveDeletedFromUsername:(NSString *)aUsername {
    NSLog(@"谁谁谁 --- %@傻逼删除了你", aUsername);
    // 刷新
    [self reloadDataSource];
    [self.tableView reloadData];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    //往聊天控制器 传递需要聊天对象的用户名
    id destVc = segue.destinationViewController;
    
    
    if ([destVc isKindOfClass:[JYJChatViewController class]]) {
        // 获取当前选择行
        NSInteger selectedRow = [self.tableView indexPathForSelectedRow].row;
        
        JYJChatViewController *chatVc = destVc;
        
        chatVc.hidesBottomBarWhenPushed = YES;
        chatVc.isGroup = NO;
        chatVc.aUsername = self.buddyList[selectedRow];
    }
}



//#pragma mark - chatManger的代理
//#pragma mark - 监听自动登录成功
//- (void)didAutoLoginWithError:(EMError *)aError {
//    if (!aError) { // 自动登录成功，此事buddyList就有值
//        self.buddyList = [[EMClient sharedClient].contactManager getContactsFromDB];
////        [self.tableView reloadData];
//    }
//}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
