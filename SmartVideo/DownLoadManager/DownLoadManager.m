//
//  DownLoadManager.m
//  SmartVideo
//
//  Created by yindongbo on 2017/4/24.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import "DownLoadManager.h"
#import <Qiniu/QiniuSDK.h>
#import <AFNetworking/AFNetworking.h>
@implementation DownLoadManager
//{
//    NSURLSessionDownloadTask *_downloadTask;
//    AFURLSessionManager *_manager;
//}

 

+ (void)qnFileUploadWithPath:(NSString *)path result:(resultBlock)block {
    QNUploadManager *uploadManager = [[QNUploadManager alloc] init];
    
    NSString *token = @"gfiz0IZ7t-E57uY4o72i7dLHKHJ2lyAR4pfXAMP4:C9u0A812iUOIBsymijT4VDgN5bU=:eyJzY29wZSI6ImRvbWJvc3BhY2UwNDI0IiwiZGVhZGxpbmUiOjE0OTMwMjk4Nzh9";
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:path]];
    
    [uploadManager putData:data key:@"" token:token complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
        NSLog(@"%@", info);
        NSLog(@"%@", resp);
    } option:nil];
}

+ (void)downLoadFileWithURL:(NSString *)url  process:(processBlock)processBlock result:(resultBlock)resultBlock {
        // 不指定文件名称进行下载自动保存，文件名自动获取
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];

        NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
            CGFloat processNum = 1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount;
            processBlock(processNum);
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
            NSString *path = [cachesPath stringByAppendingPathComponent:response.suggestedFilename];
            return [NSURL fileURLWithPath:path];

        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            NSString *localFilePath = [filePath path];
            if (!error) {
                resultBlock(localFilePath,@"下载完成",0);
            }else {
                NSLog(@"失败");
                resultBlock(@"",@"下载失败",1);
            }
        }];
    [downloadTask resume];
}
@end
