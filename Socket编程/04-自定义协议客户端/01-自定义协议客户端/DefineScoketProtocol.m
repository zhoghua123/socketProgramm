//
//  DefineScoketProtocol.m
//  01-自定义协议客户端
//
//  Created by xyj on 2018/3/7.
//  Copyright © 2018年 xyj. All rights reserved.
//

#import "DefineScoketProtocol.h"
/**
 当客户端发送的数据非常大时,数据是一帧一帧发送过来的,因此要保存起来.
 */
static NSMutableData *_dataM;
/** 总的数据包大小*/
static NSUInteger _totalSize;
/**当前的指令类型*/
static NSUInteger _commandId;

@implementation DefineScoketProtocol

+(void)load{
    _dataM = [NSMutableData data];
}

/**
 客户端协议: 4字节总数据大小 + 4字节数据类型 + N字节传输数据大小
 
 @param data 要发送的数据
 @param dataType 数据类型
 @return 协议格式化后的数据
 */
+(NSData *)useRequestProtocolWriteData:(NSData *)data andType:(PDataType)dataType{
    NSMutableData *totalData = [NSMutableData data];
    //1. 拼接长度(0-3个字节代表长度)
    //总大小 = 4个字节(表示总大小) + 4个字节(表示数据类型) + N个字节(图片数据所占字节数)
    NSUInteger totalSize = 4+4+data.length;
    //将NSUInteger转化为NSData,并且占据4个字节
    NSData *totalSizeData = [NSData dataWithBytes:&totalSize length:4];
    //拼接
    [totalData appendData:totalSizeData];
    
    //2. 拼接指令种类(4-7字节代表指令类型)
    // 0x00000001 = 图片
    // 0x00000002 = 文字
    // 0x00000003 = 位置
    // 0x00000004 = 语音
    // 用16进制表示
    NSUInteger commandId = dataType;
    //将NSUInteger转化为NSData,并且占据4个字节
    NSData *commandIdData = [NSData dataWithBytes:&commandId length:4];
    //拼接
    [totalData appendData:commandIdData];
    
    //3. 拼接图片数据(8-N代表数据)
    //拼接
    [totalData appendData:data];
    NSLog(@"客户端发送数据: 大小为:%ld==数据类型:%ld==有效数据大小:%ld",totalSize,commandId,data.length);
    return  totalData;
}

/**
 服务端协议: 4字节总数据大小 + 4字节数据类型 + 4字节响应数据大小
 
 @param dataType 数据类型
 @return 协议格式化后的数据
 */
+(NSData *)useResponseProtocolWithDataType:(PDataType)dataType{
    NSMutableData *totalDataM = [NSMutableData data];
    // 1.返回数据总字节长度(0~3:长度)
    NSUInteger totalSize = 4 + 4 + 4;
    NSData *totalSizeData = [NSData dataWithBytes:&totalSize length:4];
    [totalDataM appendData:totalSizeData];
    // 2.响应指令类型
    NSUInteger commandId = dataType;
    NSData *commandIdData = [NSData dataWithBytes:&commandId length:4];
    [totalDataM appendData:commandIdData];
    
    //3.上传的结果 //1:上传成功 0://上传失败
    NSUInteger result = 1;
    NSData *resultData = [NSData dataWithBytes:&result length:4];
    [totalDataM appendData:resultData];
    NSLog(@"服务器向客户端发出响应: 大小为:%ld==相应类型:%ld==响应状态:%ld",totalSize,commandId,result);
    return totalDataM;
}

/**
 服务器解析客户端发送的数据
 
 @param data 客户端发送的数据
 @param result 解析后的结果
 */
+(void)requestProtocolAnalyWithData:(NSData *)data andResult:(void (^)(NSUInteger, PDataType, NSData *))result{
    //1. 处理解析客户端发送过来的数据
    //第一次接收数据
    if (!_dataM.length) {
        //1.1 获取总数据包的大小
        //截取前4个字节
        NSData *totalSizeData = [data subdataWithRange:NSMakeRange(0, 4)];
        NSUInteger totalSize = 0;
        //之前是NSUInteger转化为NSData -> 现在将NSData转化为NSUInteger
        [totalSizeData getBytes:&totalSize length:4];
        _totalSize =  totalSize;
        
        //1.2 获取类型指令
        // 获取指令类型
        NSData *commandIdData = [data subdataWithRange:NSMakeRange(4, 4)];
        NSUInteger commandId = 0;
        [commandIdData getBytes:&commandId length:4];
        _commandId = commandId;
        
    }
    
    //1.3 拼接二进制
    [_dataM appendData:data];
    
    //1.4 数据已经接收完成,进行处理
    if (_dataM.length == _totalSize) {
        //1.5 将处理结果进一步处理
        NSLog(@"解析客户端: 总大小为:%ld==数据类型:%ld==有效数据大小:%ld",_totalSize,_commandId,_dataM.length-8);
        
        result(_totalSize,_commandId,_dataM);
        //1.6 数据解析完成要清空
        _dataM = [NSMutableData data];
    }
}

/**
 客户端解析服务器发送的数据
 
 @param data 服务器发送的数据
 @param result 解析后的结果
 */
//注意: 数据比较小,一帧就能发完
+(void)responseProtocolAnalyWithData:(NSData *)data andResult:(void(^)(NSUInteger totalSize,PDataType dataType,NSUInteger response))result{
    // 1. 获取总的数据包大小
    NSData *totalSizeData = [data subdataWithRange:NSMakeRange(0, 4)];
    NSUInteger totalSize = 0;
    [totalSizeData getBytes:&totalSize length:4];
    
    //2. 获取指令类型
    NSData *commandIdData = [data subdataWithRange:NSMakeRange(4, 4)];
    NSUInteger commandId = 0;
    [commandIdData getBytes:&commandId length:4];
    
    //3. 结果
    NSData *resultData = [data subdataWithRange:NSMakeRange(8, 4)];
    NSUInteger resultx = 0;
    [resultData getBytes:&resultx length:4];
    NSLog(@"服务器响应: 大小为:%ld==响应类型:%ld==响应状态:%ld",totalSize,commandId,resultx);
    //4. 返回结果值
    result(totalSize,commandId,resultx);
}
@end
