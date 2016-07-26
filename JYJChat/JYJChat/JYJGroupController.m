//
//  JYJGroupController.m
//  JYJChat
//
//  Created by JYJ on 16/7/25.
//  Copyright © 2016年 baobeikeji. All rights reserved.
//

#import "JYJGroupController.h"
#import "JYJChatViewController.h"

@interface JYJGroupController () <UITableViewDelegate, UITableViewDataSource>
/** tableView */
@property (nonatomic, weak) UITableView *tableView;
/** 群组列表 */
@property (nonatomic, strong) NSMutableArray *groupArr;
@end

@implementation JYJGroupController
- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"创建群" style:UIBarButtonItemStylePlain target:self action:@selector(rightButtonClick)];
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor redColor];
    
    
    

    // 创建群组列表
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, BXScreenW, BXScreenH) style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    [self.view addSubview:tableView];
    self.tableView = tableView;
    
    // 获取群列表
    NSArray *array = [[EMClient sharedClient].groupManager loadAllMyGroupsFromDB];
    self.groupArr = [NSMutableArray arrayWithArray:array];
    if (self.groupArr.count == 0) {
        // 从服务器获取群列表
        __weak typeof(self) weakself = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            EMError *error = nil;
            NSArray *groups = [[EMClient sharedClient].groupManager getMyGroupsFromServerWithError:&error];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!error) {
                    [weakself.groupArr removeAllObjects];
                    [weakself.groupArr addObjectsFromArray:groups];
                    [weakself.tableView reloadData];
                }
            });
        });
    }
    
}

- (void)rightButtonClick {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"创建群" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"请输入群名称";
    }];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"自我介绍";
    }];
    
    UITextField *groupName = [alert.textFields firstObject];
    UITextField *detailFiled = [alert.textFields lastObject];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        EMError *error = nil;
        EMGroupOptions *setting = [[EMGroupOptions alloc] init];
        setting.maxUsersCount = 2000;
        setting.style = EMGroupStylePublicOpenJoin;
        EMGroup *group = [[EMClient sharedClient].groupManager createGroupWithSubject:groupName.text description:detailFiled.text invitees:nil message:@"邀请您加入群组" setting:setting error:&error];
        if (!error) {
            BXLog(@"创建成功 --- %@",group);
            [self.groupArr addObject:group];
            [self.tableView reloadData];
        }
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.groupArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"GroupCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    EMGroup *group = self.groupArr[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", group.subject];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
 
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    JYJChatViewController *chatVc = [storyboard instantiateViewControllerWithIdentifier:@"JYJChatViewController"];
    chatVc.hidesBottomBarWhenPushed = YES;
    chatVc.isGroup = YES;
    chatVc.group = self.groupArr[indexPath.row];
    [self.navigationController pushViewController:chatVc animated:YES];
}

- (void)dealloc {
    [[EMClient sharedClient].groupManager removeDelegate:self];
}

@end
