//
//  ServerListener.m
//  Socket服务端
//
//  Created by xyj on 2018/3/5.
//  Copyright © 2018年 xyj. All rights reserved.
/*
 发送数据的基本要素:
    1. 如何判断(图片)数据有没有发送完成?(数据很大时,是一帧一帧的发送的)
         1. 获取数据包的总大小
         2. 如果拼接的data等于数据包的大小,就算是接收完了
    2. 还要给出该数据的类型:图片/文字/语音...
    3. 即要发送(图片)数据,又要发送过来总数据包的大小/数据类型,怎么办呢?
 此时就需要自定义协议了
 */

#import "ServerListener.h"
#import "GCDAsyncSocket.h"
#import "DefineScoketProtocol.h"
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
    //1.服务器绑定端口
    //1.1 创建一个Socket对象
    self.serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    
    //1.2 绑定端口
    NSError *err = nil;
    [self.serverSocket acceptOnPort:5288 error:&err];
    if(err){
        NSLog(@"端口开启失败(服务开启失败)");
    }else{
        NSLog(@"服务开启成功");
    }
}
#pragma mark - GCDAsyncSocketDelegate
//    2.监听客户端的连接
-(void)socket:(GCDAsyncSocket *)serverSocket didAcceptNewSocket:(GCDAsyncSocket *)clientSocket{
    NSLog(@"有客户端请求连接");
    //3.允许客户端建立连接
    [self.clientSockets addObject:clientSocket];
    //3.1调用客户端的读取数据的方法，这样读取数据的代理方法才会调用
    [clientSocket readDataWithTimeout:-1 tag:0];
}
// 4.读取客户端的请求数据
-(void)socket:(GCDAsyncSocket *)clientSocket didReadData:(NSData *)data withTag:(long)tag{
    //1.解析客户端发送过来的数据
    [DefineScoketProtocol requestProtocolAnalyWithData:data andResult:^(NSUInteger totalSize, PDataType dataType, NSData *inputData) {
        NSLog(@"数据已经接收完成");
        switch (dataType) {
            case PDataTypePic:
                NSLog(@"此次请求是上传图片 ");
                [self saveImageWithData:data];
                break;
            case PDataTypeText:
                NSLog(@"此次请求是上传文字");
                [self handleTextWithData:data];
                break;
            default:
                break;
        }
        //3. 处理完成,给客户端发出响应数据
        [self responseToClient:clientSocket andDataType:dataType];
    }];
    
   //2. 下次还想接收数据 ，也需要调用一个方法 客户端的 readDataWithTimeout:tag:方法
    [clientSocket readDataWithTimeout:-1 tag:0];
}

#pragma mark - defineDealWithData
//处理文字
-(void)handleTextWithData:(NSData *)data{
    // 1.转化字符串
    NSString *receviceStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"客户端发来的文本信息为: %@",receviceStr);
}
//处理图片
-(void)saveImageWithData:(NSData *)data{
    // 1.生成图片路径
    NSString *imgPath = @"/Users/xyj/Desktop/img/xxxx.png";
    //2. 写入文件
    [data writeToFile:imgPath atomically:YES];
}

//服务端发送完成,要响应:  服务端自定义响应协议 4个字节总大小+4个字节的类型+ 4个字节的返回内容
-(void)responseToClient:(GCDAsyncSocket *)clientSocket andDataType:(PDataType)dataType{
    
    //1. 根据自定义的响应协议组装数据
  NSData *totalDataM  = [DefineScoketProtocol useResponseProtocolWithDataType:dataType];
    //2.服务端响应数据
    [clientSocket writeData:totalDataM withTimeout:-1 tag:0];
}
@end
