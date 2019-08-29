//
//  WJShootButton.m
//  WJCamera
//
//  Created by wangwenj on 2019/8/15.
//  Copyright © 2019 wangwenj. All rights reserved.
//

#import "WJShootButton.h"
#import "WJUtilDefine.h"

@implementation WJShootButton


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
    self.layer.cornerRadius = VIEW_W(self)/2;
    self.layer.borderWidth  = 5;
    self.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.layer addSublayer:self.fillLayer];
    self.fillLayer.path = self.ovalInRectPath.CGPath;
}

-(CAShapeLayer * )fillLayer{
    //Create parameters to draw progress
    if (!_fillLayer ) {
        _fillLayer = [CAShapeLayer layer];
        _fillLayer.frame = CGRectMake(8,8,VIEW_W(self)-16 , VIEW_H(self)-16 );
        _fillLayer.fillColor = self.defaultFillColor;
    }
    return _fillLayer;
}

-(CGColorRef)defaultFillColor{
    return UIColor.redColor.CGColor;
}

// 圆形
- (UIBezierPath *)ovalInRectPath
{
    double width = VIEW_W(self)-16;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, width, width) cornerRadius:width/2];
    return path;
}

// 圆角矩形
- (UIBezierPath *)rounderRectPath
{
    double width = VIEW_W(self)-30;
    return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(7, 7, width, width) cornerRadius:5];
}


- (CABasicAnimation *)animationTouchbegin
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.duration = 0.25;
    animation.fromValue = (__bridge id)(self.ovalInRectPath.CGPath);
    animation.toValue = (__bridge id)(self.rounderRectPath.CGPath);
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    return animation;
}

- (CABasicAnimation *)animationTouchend
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.duration = 0.25;
    animation.fromValue = (__bridge id)(self.rounderRectPath.CGPath);
    animation.toValue = (__bridge id)(self.ovalInRectPath.CGPath);
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    return animation;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    [self.fillLayer addAnimation:[self animationTouchbegin] forKey:@"animate"];
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesEnded:touches withEvent:event];
    [self.fillLayer addAnimation:[self animationTouchend] forKey:@"animate"];
}





@end
