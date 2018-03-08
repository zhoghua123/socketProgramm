//
//  main.m
//  Socket服务端
//
//  Created by xyj on 2018/3/5.
//  Copyright © 2018年 xyj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServerListener.h"
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        NSLog(@"Hello, World!");
        //1.开启10086服务
        ServerListener *server = [[ServerListener alloc] init];
        [server start];
        
        //2.让程序不死(开启主运行循环)
        //因为是主线程不需要添加source或者timer,本来就有.子线程的话还要主动添加source和timer
        [[NSRunLoop mainRunLoop] run];
    }
    return 0;
}
