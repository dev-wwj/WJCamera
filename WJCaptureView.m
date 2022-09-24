//
//  WJCaptureView.m
//  WJCamera
//
//  Created by wangwenj on 2019/8/14.
//  Copyright © 2019 wangwenj. All rights reserved.
//

#import "WJCaptureView.h"

#define Width_Progress 6
@interface WJCaptureView()

@property (strong, nonatomic) CAShapeLayer *bgLayer;
@property (strong, nonatomic) CAShapeLayer *ringLayer;
@property (strong, nonatomic) CAShapeLayer *centerLayer;
@property (assign, nonatomic) NSInteger takeMode;
@end

@implementation WJCaptureView


- (instancetype)initWithTakeMode:(NSInteger)takeMode {
    self = [super init];
    if (self) {
        self.takeMode = takeMode;
        [self setupUI];
    }
    return self;
}

- (void)setProgress:(CGFloat)progress{
    _progress = progress;
    self.ringLayer.strokeEnd = _progress;
}

- (void)layoutSubviews {
    [self ringLayer];
    self.centerLayer.path = [self ovalInRectPath].CGPath;
}

- (CAShapeLayer *)bgLayer {
    if (!_bgLayer) {
        _bgLayer = [CAShapeLayer layer];
        _bgLayer.frame = self.bounds;
        _bgLayer.fillColor = [UIColor colorWithWhite:0.8 alpha:1.0].CGColor;
        _bgLayer.path = [UIBezierPath bezierPathWithOvalInRect:self.bounds].CGPath;
        [self.layer addSublayer:_bgLayer];
    }
    return _bgLayer;
}

- (CAShapeLayer *)ringLayer {
    if (!_ringLayer) {
        _ringLayer = [CAShapeLayer layer];
        CGFloat width = CGRectGetWidth(self.bounds) -Width_Progress;
        CGRect rect = CGRectMake(Width_Progress/2, Width_Progress/2, width, width);
        _ringLayer.frame = rect;
        _ringLayer.fillColor = UIColor.clearColor.CGColor;
        _ringLayer.strokeColor = _progressColor.CGColor;
        _ringLayer.lineWidth = Width_Progress;
        _ringLayer.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, width, width)].CGPath;
        _ringLayer.strokeStart = 0.0;
        _ringLayer.strokeEnd = 0.0;
        [self.bgLayer addSublayer:_ringLayer];
    }
    return _ringLayer;
}

- (CAShapeLayer *)centerLayer {
    if (!_centerLayer) {
        _centerLayer = [CAShapeLayer layer];
        _centerLayer.frame = self.bounds;
        _centerLayer.fillColor = UIColor.whiteColor.CGColor;
        [self.layer addSublayer:_centerLayer];
    }
    return _centerLayer;
}

- (void)setupUI {
    CGAffineTransform transform = CGAffineTransformIdentity;
    self.transform = CGAffineTransformRotate(transform, -M_PI/2);
    if (self.takeMode == 1) {
        [self addTarget:self action:@selector(touchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    }else if (self.takeMode == 2) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        longPress.minimumPressDuration = 0.5; //定义按的时间
        [self addGestureRecognizer:longPress];
    }else {
        [self addTarget:self action:@selector(touchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        longPress.minimumPressDuration = 0.5; //定义按的时间
        [self addGestureRecognizer:longPress];
    }
    
    
}

-(void)touchUpInside:(id)sender{
    if (_block) {
        _block(Tap);
    }
}

-(void)longPress:(UILongPressGestureRecognizer *)recognizer{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        if (_block) {
            _block(LongPress);
        }
        [self.bgLayer addAnimation:[self enlargedAnimation] forKey:@"transform"];
    }else if(recognizer.state == UIGestureRecognizerStateEnded){
        if (_block) {
            _block(EndLongPress);
        }
        [self.centerLayer addAnimation:[self centerAnimationTouchend] forKey:@"animate"];
        [self.bgLayer removeAnimationForKey:@"transform"];
    }
}

// 圆形
- (UIBezierPath *)ovalInRectPath
{
    double width = CGRectGetWidth(self.bounds) - 30;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(15, 15, width, width) cornerRadius:width/2];
    return path;
}

// 圆角矩形
- (UIBezierPath *)rounderRectPath
{
    double width = CGRectGetWidth(self.bounds) - 50;
    return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(25, 25, width, width) cornerRadius:5];
}


- (CABasicAnimation *)centerAnimationTouchbegin
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.duration = 0.2;
    animation.fromValue = (__bridge id)(self.ovalInRectPath.CGPath);
    animation.toValue = (__bridge id)(self.rounderRectPath.CGPath);
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    return animation;
}

- (CABasicAnimation *)centerAnimationTouchend
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.duration = 0.2;
    animation.fromValue = (__bridge id)(self.rounderRectPath.CGPath);
    animation.toValue = (__bridge id)(self.ovalInRectPath.CGPath);
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    return animation;
}

// 放大
- (CABasicAnimation*)enlargedAnimation {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
    animation.duration = 0.2;
    animation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2f, 1.2f, 1.0f)];
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    return animation;
}

- (CABasicAnimation*)recoverTransAnimation {
    CABasicAnimation *animation = [self.bgLayer animationForKey:@"transform"];
    animation.removedOnCompletion = YES;
    return animation;
}



-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    [self.centerLayer addAnimation:[self centerAnimationTouchbegin] forKey:@"animate"];
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesEnded:touches withEvent:event];
    [self.centerLayer addAnimation:[self centerAnimationTouchend] forKey:@"animate"];
}


@end
