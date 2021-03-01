//
//  CaptureView.h
//  WJCamera
//
//  Created by wangwenj on 2019/8/14.
//  Copyright © 2019 wangwenj. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "WJProgressView.h"

typedef NS_ENUM(NSInteger,CaptureAction) {
    Tap,
    LongPress,
    EndLongPress,
};

typedef void(^CaptureBlock)(CaptureAction action);

@interface CaptureView : UIControl

@property(assign, nonatomic) CGFloat progress;

@property(strong, nonatomic) UIColor *progressColor;

@property(copy, nonatomic) CaptureBlock block;

@end

