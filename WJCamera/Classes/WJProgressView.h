//
//  WJProgressView.h
//  WJCamera
//
//  Created by wangwenj on 2019/8/14.
//  Copyright © 2019 wangwenj. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WJProgressView : UIView

@property(assign,nonatomic)NSInteger timerMax;     //default is 10
@property(assign,nonatomic)CGFloat progressRingWidth;  //default is 5
@property(assign,nonatomic)UIColor *strokeColor;  //efault is greenColor

-(void)startAnimation;
-(void)endAnimation;

@end

NS_ASSUME_NONNULL_END
