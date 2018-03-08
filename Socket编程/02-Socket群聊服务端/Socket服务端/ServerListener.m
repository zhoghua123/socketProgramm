//
//  ServerListener.m
//  Socket服务端
//
//  Created by xyj on 2018/3/5.
//  Copyright © 2018年 xyj. All rights reserved.
//

#import "ServerListener.h"
#import "GCDAsyncSocket.h"

@interface ServerListener()<GCDAsyncSocketDelegate>
//当前服务端的socket对象
@property(strong,nonatomic)GCDAsyncSocket *serverSocket;
//用于存储所有的客户端Socket对象(多个客户端访问该服务)
@property(nonatomic,strong)NSMutableArray *clientSockets;

@end

@implementation ServerListener

-(NSMutableArray *)clientSockets{
    if(!_clientSockets){
        _clientSockets = [NSMutableArray array];
    }
    
    return _clientSockets;
}

-(void)start{
    //    1.服务器绑定端口
    //1.1 socket():创建一个Socket对象(当前服务端socket对象)
    //delegateQueue: 代理方法在那个线程调用.
    self.serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    
    
    //1.2 bind():绑定端口(开启一个端口)，监听客户端面的连接(给这个服务器设置一个端口)
    NSError *err = nil;
    [self.serverSocket acceptOnPort:5288 error:&err];
    if(err){
        NSLog(@"端口开启失败(服务开启失败)");
    }else{
        NSLog(@"服务开启成功");
    }
}
#pragma mark - GCDAsyncSocketDelegate
//    2.listen():监听客户端的连接
-(void)socket:(GCDAsyncSocket *)serverSocket didAcceptNewSocket:(GCDAsyncSocket *)clientSocket{
    //    3.accept(): 允许客户端建立连接(实际操作就是把客户端的socket强引用起来,不让他死掉)
    //3.1把客户端socket存储到一个数组
    //如果不强制引用客户端的socket的话,就会销毁,然后断开连接
    [self.clientSockets addObject:clientSocket];
    NSLog(@"有客户端连接 %zd",self.clientSockets.count);
    
    
    //3.3调用客户端的读取数据的方法，这样读取数据的代理方法才会调用
    /**
     * -1:代表不超时
     * 0:随便写，现在用不到
     */
    [clientSocket readDataWithTimeout:-1 tag:0];
}
//    4.读取客户端的请求数据
#warning 要使用这个代理方法读取数据前，需要调用一个方法 客户端的 readDataWithTimeout:tag:方法
-(void)socket:(GCDAsyncSocket *)clientSocket didReadData:(NSData *)data withTag:(long)tag{
    
    //读取数据:把data -> string
    NSString *readStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@",readStr);
    
#warning 下次还想接收数据 ，也需要调用一个方法 客户端的 readDataWithTimeout:tag:方法
    [clientSocket readDataWithTimeout:-1 tag:0];
    
    //转发
    for(GCDAsyncSocket *socket in self.clientSockets){
        //不能转发给自己
        if(socket != clientSocket){
            [socket writeData:data withTimeout:-1 tag:0];
        }
    }
}

-(void)stop{
}
@end
