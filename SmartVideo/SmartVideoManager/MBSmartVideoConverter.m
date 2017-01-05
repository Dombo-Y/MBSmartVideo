//
//  MBSmartVideoConverter.m
//  SmartVideo
//
//  Created by yindongbo on 17/1/5.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import "MBSmartVideoConverter.h"
#import <ImageIO/ImageIO.h>

@interface MBGenerateGifImageManager : NSObject

@property (nonatomic, strong) NSOperationQueue *generateQueue;

+ (instancetype)shareInstance;
- (NSOperationQueue *)addOperationWithBlock:(void (^)(void))block;
@end

@implementation MBGenerateGifImageManager

- (instancetype)init {
    self = [super init];
    if (self)
    {
        _generateQueue = [[NSOperationQueue alloc] init];
        _generateQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

+ (instancetype)shareInstance {
    static MBGenerateGifImageManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[MBGenerateGifImageManager alloc] init];
    });
    return manager;
}

- (NSOperation *)addOperationWithBlock:(void (^)(void))block {
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        block();
    }];
    [_generateQueue addOperation:operation];
    
    return operation;
}
@end


@interface MBSmartVideoConverter()

@property (nonatomic, strong) NSOperationQueue *generateQueue;
@end

@implementation MBSmartVideoConverter

static void makeAnimatedGif(NSArray *images, NSURL *gifURL, NSTimeInterval duration) {
    NSTimeInterval perSecond = duration/images.count;
    NSDictionary *fileProperties = @{
                                     (__bridge id)kCGImagePropertyGIFDictionary: @{
                                             (__bridge id)kCGImagePropertyGIFLoopCount: [NSNumber numberWithInteger:duration],
                                             }
                                     };
    
    NSDictionary *frameProperties = @{
                                      (__bridge id)kCGImagePropertyGIFDictionary: @{
                                              (__bridge id)kCGImagePropertyGIFDelayTime: @(perSecond),
                                              }
                                      };
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)gifURL, kUTTypeGIF, images.count, NULL);
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)fileProperties);
    
    for (UIImage *image in images)
    {
        @autoreleasepool
        {
            CGImageDestinationAddImage(destination, image.CGImage, (__bridge CFDictionaryRef)frameProperties);
        }
    }
    
    if (!CGImageDestinationFinalize(destination))
    {
        NSLog(@"failed to finalize image destination");
    }
    else
    {
      CFRelease(destination);
    }
}


+ (UIImage *)convertSampleBufferRefToUIImage:(CMSampleBufferRef)sampleBufferRef
{
    @autoreleasepool
    {
        CGImageRef cgImage = [self convertSamepleBufferRefToCGImage:sampleBufferRef];
        UIImage *image;
        
        CGFloat height = CGImageGetHeight(cgImage);
        CGFloat width = CGImageGetWidth(cgImage);
        
        height = height / 5;
        width = width / 5;
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, [UIScreen mainScreen].scale);
        
#define UseUIImage 0
#if UseUIImage
        
        [image drawInRect:CGRectMake(0, 0, width, height)];
#else
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(context, 0, height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
#endif
        image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        CGImageRelease(cgImage);
        
        UIGraphicsEndImageContext();
        return image;
    }
}


// Create a UIImage from sample buffer data
// 官方回答 https://developer.apple.com/library/ios/qa/qa1702/_index.html
+ (CGImageRef)convertSamepleBufferRefToCGImage:(CMSampleBufferRef)sampleBufferRef {
    @autoreleasepool {
        
        // Get a CMSampleBuffer's Core Video image buffer for the media data
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBufferRef);
        // Lock the base address of the pixel buffer
        CVPixelBufferLockBaseAddress(imageBuffer, 0);
        
        // Get the number of bytes per row for the pixel buffer
        void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
        
        // Get the number of bytes per row for the pixel buffer
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        // Get the pixel buffer width and height
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        
        // Create a device-dependent RGB color space
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        // Create a bitmap graphics context with the sample buffer data
        CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                     bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        // Create a Quartz image from the pixel data in the bitmap graphics context
        CGImageRef quartzImage = CGBitmapContextCreateImage(context);
        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
        
        // Free up the context and color space
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
        
        return quartzImage;
    }
}


#pragma mark - GIF
+ (void)convertVideoToGifImageWithURL:(NSURL *)url destinationUrl:(NSURL *)destinationUrl finishBlock:(void (^)(void))finishBlock {

    [self convertVideoUIImagesWithURL:url finishBlock:^(NSArray *images, NSTimeInterval duration) {
        [[MBGenerateGifImageManager shareInstance] addOperationWithBlock:^{
            makeAnimatedGif(images, destinationUrl, duration);
            dispatch_async(dispatch_get_main_queue(), ^{
                finishBlock();
            });
        }];
    }];
}

//转成UIImage
+ (void)convertVideoUIImagesWithURL:(NSURL *)url finishBlock:(void (^)(id images, NSTimeInterval duration))finishBlock {
    
    AVAsset *asset = [AVAsset assetWithURL:url];
    NSError *error = nil;
    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
    NSTimeInterval duration = CMTimeGetSeconds(asset.duration);
 
    dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(backgroundQueue, ^{
        if (error)
        {
            NSLog(@"%@",[error localizedDescription]);
        }
        
        NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        AVAssetTrack *videoTrack = [videoTracks firstObject];
        if (!videoTrack) {
            return ;
        }
        
        int m_pixelFormatType;
        //     视频播放时，
        m_pixelFormatType = kCVPixelFormatType_32BGRA;
        
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        [options setObject:@(m_pixelFormatType) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        AVAssetReaderTrackOutput *videoReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:options];
        
        if ([reader canAddOutput:videoReaderOutput])
        {
            [reader addOutput:videoReaderOutput];
        }
        [reader startReading];
        
        NSMutableArray *images = [NSMutableArray array];
        while ([reader status] == AVAssetReaderStatusReading && videoTrack.nominalFrameRate > 0)
        {
            @autoreleasepool {
                // 读取 video sample
                CMSampleBufferRef videoBuffer = [videoReaderOutput copyNextSampleBuffer];
                
                if (!videoBuffer) {
                    break;
                }
                
                [images addObject:[MBSmartVideoConverter convertSampleBufferRefToUIImage:videoBuffer]];
                
                CFRelease(videoBuffer);
            }
        }
        if (finishBlock)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                finishBlock(images, duration);
            });
        }
    });
}
@end
