//
//  ViewController.m
//  01-自定义协议客户端
//
//  Created by xyj on 2018/3/7.
//  Copyright © 2018年 xyj. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"
#import "DefineScoketProtocol.h"
@interface ViewController ()<GCDAsyncSocketDelegate>
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
/** 客户端的Socket */
@property (nonatomic ,strong) GCDAsyncSocket *clientSocket;
@end

@implementation ViewController


- (IBAction)connectToHost:(id)sender {
    // 1.创建一个socket对象
    if (self.clientSocket == nil) {
        self.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    
    // 2.连接服务器
    NSError *error = nil;
    [self.clientSocket connectToHost:@"172.16.15.43" onPort:5288 error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
}
//断开连接
- (IBAction)closeToHost:(id)sender {
    [self.clientSocket disconnect];
}

//发送文本信息
- (IBAction)sendText:(id)sender {
    //1. 拿到文本data
    NSString *text = @"Hello,自定义协议";
    NSData *textData = [text dataUsingEncoding:NSUTF8StringEncoding];
    
    //2. 根据自定义协议,组装数据格式
    NSData *totalDataM = [DefineScoketProtocol useRequestProtocolWriteData:textData andType:PDataTypeText];
    
    //3. 将自定义协议格式的数据发送给服务器
    [self.clientSocket writeData:totalDataM withTimeout:-1 tag:0];
}

//发送图片
- (IBAction)sendImag:(id)sender {
    
    //1.把图片转化为NSData
    UIImage *image = [UIImage imageNamed:@"IMG_2427.JPG"];
    NSData *imgdata = UIImagePNGRepresentation(image);
   
    //2. 根据自定义协议,组装数据格式
    NSData *totalData = [DefineScoketProtocol useRequestProtocolWriteData:imgdata andType:PDataTypePic];
    //imgdata.length:拿到的就是图片数据所占的字节数;
    NSLog(@"图片的字节大小:%ld",imgdata.length);
    NSLog(@"发送数据的总字节大小:%ld",totalData.length);
    //3. 将自定义协议格式的数据发送给服务器
    [self.clientSocket writeData:totalData withTimeout:-1 tag:0];
    
}

#pragma mark - GCDAsyncSocketDelegate
// 与服务器连接成功
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    
    self.statusLabel.text = @"连接中..";
    self.statusLabel.backgroundColor = [UIColor greenColor];
    
#warning 读取数据
    [sock readDataWithTimeout:-1 tag:0];
}

//与服务器断开连接
-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    NSLog(@"%@",err);
    self.statusLabel.text = @"断开..";
    self.statusLabel.backgroundColor = [UIColor redColor];
}
/**
 *  解析服务器返回的数据
 */
// 接收服务器响应的数据
-(void)socket:(GCDAsyncSocket *)clientSocket didReadData:(NSData *)data withTag:(long)tag{
    
    //1. 解析服务器的响应
    [DefineScoketProtocol responseProtocolAnalyWithData:data andResult:^(NSUInteger totalSize, PDataType dataType, NSUInteger response) {
        NSMutableString *str = [NSMutableString string];
        if (dataType == PDataTypePic) {//图片
            [str appendString:@"图片 "];
        }else if(dataType == PDataTypeText){//文字
            [str appendString:@"文字 "];
        }
        
        if(response == 1){
            [str appendString:@"上传成功"];
        }else{
            [str appendString:@"上传失败"];
        }
        
        NSLog(@"%@",str);
    }];
    
#warning 可以接收下一次数据
    [clientSocket readDataWithTimeout:-1 tag:0];
    
}
@end
