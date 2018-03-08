//
//  ViewController.m
//  Socket客户端
//
//  Created by xyj on 2018/3/5.
//  Copyright © 2018年 xyj. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"
@interface ViewController ()<GCDAsyncSocketDelegate>
@property (weak, nonatomic) IBOutlet UITextField *field;
@property(nonatomic,strong)GCDAsyncSocket *clientSocket;
@property(nonatomic,strong)NSMutableArray *messages;
@end
//1.连接到服务器（IP+Port）
//2.监听连接服务器是否成功
//3.如果连接成功，就可发送消息给服务器
//4.监听服务器转发过来的消息
//5.发送时，刷新表格显示数据
//6.接收聊天消息时，刷新表格显示数据
@implementation ViewController

-(NSMutableArray *)messages{
    if(!_messages){
        _messages = [NSMutableArray array];
    }
    return _messages;
}

//1.连接到服务器（IP+Port）
- (IBAction)connectToHostAction:(id)sender {
    //1.1创建一个Socket对象
    self.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    
    //1.2连接服务器
    NSError *err = nil;
    [self.clientSocket connectToHost:@"172.16.15.43" onPort:5288 error:&err];
    //err实际上没有什么太大的作用
    if(!err){
        NSLog(@"连接请求发送成功");
    }else{
        NSLog(@"连接请求发送失败");
    }
}
//3.如果连接成功，就可发送消息给服务器
- (IBAction)sendAction:(id)sender {
    //获取发送的聊天内容
    NSString *text = self.field.text;
    
    //添加换行
    text = [NSString stringWithFormat:@"%@\n",text];
    
    //发送
    [self.clientSocket writeData:[text dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
    
    //清空内容
    self.field.text = nil;
    
    //5.发送时，刷新表格显示数据
    [self.messages addObject:text];
    
    [self.tableView reloadData];
}


#pragma mark - GCDAsyncSocketDelegate
//2.监听连接服务器是否成功
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    
    NSLog(@"连接服务器成功");
#warning 调用下面的方法，目的是为了读取数据的代理方法能调用
    [self.clientSocket readDataWithTimeout:-1 tag:0];
}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    NSLog(@"连接服务器失败 %@",err);
}

//4.监听服务器转发过来的消息
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    //默认读取数据的方法是不会调用
    //Data - String
    NSString *recStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
#warning 调用下面的方法，目的是为了下次还能接收数据
    [self.clientSocket readDataWithTimeout:-1 tag:0];
    
    NSLog(@"%@",recStr);
    NSLog(@"%@",[NSThread currentThread]);
    
    //6.接收聊天消息时，刷新表格显示数据
    [self.messages addObject:recStr];
    
#warning 此方法是在是在子线程调用的，所以不能刷新UI
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.tableView reloadData];
    }];
}

#pragma mark- UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.messages.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *ID = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:0 reuseIdentifier:ID];
    }
    
    //显示内容
    cell.textLabel.text = self.messages[indexPath.row];
    
    return cell;
    
}
@end
