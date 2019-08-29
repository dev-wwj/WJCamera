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


typedef NS_ENUM(NSInteger,CaptureAction) {
    CAPTURE_TAKE_PIC,
    CAPTURE_RECORD_START,
    CAPTURE_RECORD_END
};

typedef void(^CaptureBlock)(CaptureAction action);

@interface CaptureView : UIView

@property(strong, nonatomic) WJShootButton *captureButton;
@property(strong, nonatomic) WJProgressView * progerssView;

@property(assign, nonatomic) NSInteger Max_timer; // 最长录制时间
@property(assign, nonatomic) NSInteger Min_timer; // 最短录制时间

@property(copy, nonatomic) CaptureBlock block;

-(void)reset;

@end

