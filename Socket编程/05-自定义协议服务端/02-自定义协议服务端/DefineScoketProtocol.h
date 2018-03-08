//
//  DefineScoketProtocol.h
//  01-自定义协议客户端
//
//  Created by xyj on 2018/3/7.
//  Copyright © 2018年 xyj. All rights reserved.
//
//这个类主要是用来定制客户单与服务器之间的协议

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    PDataTypeText = 0x00000001,
    PDataTypeAudio = 0x00000002,
    PDataTypePic = 0x00000003,
    PDataTypeLocation = 0x00000004
} PDataType;
@interface DefineScoketProtocol : NSObject

/*******客户端部分*********/
/**
 客户端协议: 4字节总数据大小 + 4字节数据类型 + N字节传输数据大小

 @param data 要发送的数据
 @param dataType 数据类型
 @return 协议格式化后的数据
 */
+(NSData *)useRequestProtocolWriteData:(NSData *)data andType:(PDataType)dataType;

/**
 客户端解析服务器发送的数据
 
 @param data 服务器发送的数据
 @param result 解析后的结果
 */
+(void)responseProtocolAnalyWithData:(NSData *)data andResult:(void(^)(NSUInteger totalSize,PDataType dataType,NSUInteger response))result;

/*******服务器部分*********/
/**
 服务器解析客户端发送的数据

 @param data 客户端发送的数据
 @param result 解析后的结果
 */
+(void)requestProtocolAnalyWithData:(NSData *)data andResult:(void(^)(NSUInteger totalSize,PDataType dataType,NSData *inputData))result;
/**
 服务端协议: 4字节总数据大小 + 4字节数据类型 + 4字节响应数据大小
 
 @param dataType 数据类型
 @return 协议格式化后的数据
 */
+(NSData *)useResponseProtocolWithDataType:(PDataType)dataType;

@end
