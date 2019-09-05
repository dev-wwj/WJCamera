//
//  WJProgressView.m
//  WJCamera
//
//  Created by wangwenj on 2019/8/14.
//  Copyright © 2019 wangwenj. All rights reserved.
//

#import "WJProgressView.h"
#import "WJUtilDefine.h"

@interface WJProgressView()<CAAnimationDelegate>
@property(strong, nonatomic)CAShapeLayer *progressLayer;

@property(strong, nonatomic)CABasicAnimation *basicAnimation;
@end


@implementation WJProgressView


-(instancetype)init{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}


-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

-(void)setup{
    self.progressRingWidth = 5;
    self.strokeColor = UIColor.greenColor;
}

-(void)startAnimation{
    [self.layer addSublayer:self.progressLayer];
    [self.progressLayer addAnimation:[self basicAnimation] forKey:@"progerssAnimition"];
}

-(void)endAnimation{
    [self.progressLayer removeFromSuperlayer];
}

-(CAShapeLayer * )progressLayer{
    //Create parameters to draw progress
    if (!_progressLayer ) {
        _progressLayer = [CAShapeLayer layer];
        _progressLayer.frame = self.bounds;
        _progressLayer.lineWidth = _progressRingWidth;
        _progressLayer.fillColor = [UIColor clearColor].CGColor;
        _progressLayer.strokeColor = _strokeColor.CGColor;
        //圆的起始位置，默认为0
        _progressLayer.strokeStart = 0;
        //圆的结束位置，默认为1，如果值为0.75，则显示3/4的圆
        _progressLayer.strokeEnd = 1;
        _progressLayer.lineCap = kCALineCapRound;
        _progressLayer.lineJoin = kCALineJoinMiter;
        _progressLayer.path = [self circlePath].CGPath;
    }
    return _progressLayer;
}

-(void)setStrokeColor:(UIColor *)strokeColor{
    if (_strokeColor != strokeColor) {
        _strokeColor = strokeColor;
        _progressLayer.strokeColor = _strokeColor.CGColor;
    }
}

-(void)setProgressRingWidth:(CGFloat)progressRingWidth{
    if (_progressRingWidth != progressRingWidth) {
        _progressRingWidth = progressRingWidth;
        _progressLayer.lineWidth = progressRingWidth;
    }
}

// 圆形
- (UIBezierPath *)circlePath
{
    return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, VIEW_W(self), VIEW_H(self)) cornerRadius:VIEW_W(self)/2];
}


// key 为strokeStart的animate
- (CABasicAnimation *)basicAnimation
{
    if (!_basicAnimation) {
        CABasicAnimation *animate = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        animate.duration = _timeMax;
        animate.fromValue = @(0);
        animate.toValue = @(1);
        animate.fillMode = kCAFillModeForwards;
        animate.removedOnCompletion = NO;
        animate.delegate = self;
        _basicAnimation = animate;
    }
    return _basicAnimation;
}

/**
 *  动画确实停止了
 *
 *  @param anim CAAnimation对象
 *  @param flag 是否是正常的移除
 */
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    NSLog(@"动画:%@ 是否动画中途被移除了:%d", anim, flag);
    [self.progressLayer removeFromSuperlayer];
}

/**
 *  暂停
 *
 *  @param layer 被停止的layer
 */
-(void)pauseLayer:(CALayer*)layer
{
    CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
    layer.speed               = 0.0;
    layer.timeOffset          = pausedTime;
}

/**
 *  恢复
 *
 *  @param layer 被恢复的layer
 */
-(void)resumeLayer:(CALayer*)layer
{
    CFTimeInterval pausedTime     = [layer timeOffset];
    layer.speed                   = 1.0;
    layer.timeOffset              = 0.0;
    layer.beginTime               = 0.0;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    layer.beginTime               = timeSincePause;
}

-(void)removeLayer:(CALayer *)layer{
    [layer removeFromSuperlayer];
}
@end
