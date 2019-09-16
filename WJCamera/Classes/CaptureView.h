//
//  CaptureView.h
//  WJCamera
//
//  Created by wangwenj on 2019/8/14.
//  Copyright © 2019 wangwenj. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "WJProgressView.h"
#import "WJShootButton.h"
#import "WJCameraConfig.h"


typedef NS_ENUM(NSInteger,CaptureAction) {
    CAPTURE_TAKE_PIC,
    CAPTURE_RECORD_START,
    CAPTURE_RECORD_END
};

typedef void(^CaptureBlock)(CaptureAction action);

@interface CaptureView : UIView

@property(strong, nonatomic) WJShootButton *captureButton;
@property(strong, nonatomic) WJProgressView * progerssView;
@property(strong, nonatomic) UILongPressGestureRecognizer *longPress;

@property(assign, nonatomic) NSInteger Max_time; // 最长录制时间
@property(assign, nonatomic) NSInteger Min_time; // 最短录制时间

@property(assign, nonatomic)  CAMERA_TAKE_MODE takeMode; //相机类型


@property(assign, nonatomic) BOOL isEndTime;

@property(copy, nonatomic) CaptureBlock block;

-(void)reset;

@end

