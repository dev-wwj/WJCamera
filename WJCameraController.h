//
//  WJCameraController.h
//  WJCamera
//
//  Created by wangwenj on 2019/8/14.
//  Copyright © 2019 wangwenj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

typedef NS_ENUM(NSInteger, CAMERA_TAKE_MODE) {
    ALL = 0,
    PHOTO,
    VIDOE
};

@protocol CameraDelegate <NSObject>


- (void)recodeVideoComplete:(NSURL *_Nullable)videoPath;

- (void)takePhotoComplete:(UIImage *_Nullable)image;

@optional
- (void)recordLessMinDuration;

@end

@interface WJCameraController : UIViewController


@property(nonatomic, copy) AVCaptureSessionPreset _Nullable previewSessionPreset;  // 设置预览图像分辨率 (default AVCaptureSessionPresetHigh)

@property(nonatomic, assign) CAMERA_TAKE_MODE takeMode;

@property(nonatomic, assign) NSTimeInterval minDuration,maxDuration;  // 视频录制时长（defalut 3.0-15.0）

@property(nonatomic, strong) UIColor * _Nullable progressColor;  // 进度条颜色


@property(nullable, weak) id <CameraDelegate> delegate;

- (instancetype _Nullable )initWithTakeMode:(CAMERA_TAKE_MODE) takeMode delegate:(id<CameraDelegate>_Nullable)delegate;

@end

