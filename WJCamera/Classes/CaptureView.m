//
//  CaptureView.m
//  WJCamera
//
//  Created by wangwenj on 2019/8/14.
//  Copyright © 2019 wangwenj. All rights reserved.
//

#import "CaptureView.h"
#import "WJUtilDefine.h"

@implementation CaptureView

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

-(void)setMax_time:(NSInteger)Max_time{
    if (_Max_time != Max_time) {
        _Max_time = Max_time;
        _progerssView.timeMax = _Max_time;
    }
}

-(void)setup{
    _progerssView = [[WJProgressView alloc] initWithFrame:self.bounds];
    [self addSubview:_progerssView];
    _captureButton = [[WJShootButton alloc]initWithFrame:CGRectMake(0, 0, 60, 60 )];
    _captureButton.center = CGPointMake(VIEW_W(self)/2, VIEW_H(self)/2);
    _captureButton.fillLayer.fillColor = UIColor.redColor.CGColor;
    [self addSubview:_captureButton];
    
    _longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(pressForShoot:)];
    _longPress.minimumPressDuration = 0.5; //定义按的时间
    [_captureButton addGestureRecognizer:_longPress];
    [self reset];
}

-(void)reset{
    [_captureButton addTarget:self action:@selector(takeShoot:) forControlEvents:UIControlEventTouchUpInside];
}

-(void)takeShoot:(id)sender{
    if (_block) {
        _block(CAPTURE_TAKE_PIC);
    }
}

-(void)pressForShoot:(UILongPressGestureRecognizer *)recognizer{
    //拍摄时移除点击target ；只响应longPress；
    [_captureButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        NSLog(@"%@",@"press_begin");
        [self.progerssView startAnimation];
        _isEndTime = NO;
        [self performSelector:@selector(endOfTimeRecord) withObject:nil afterDelay:_Max_time]; // 最大录制时间到后结束
        if (_block) {
            _block(CAPTURE_RECORD_START);
        }
    }else if(recognizer.state == UIGestureRecognizerStateEnded){
         NSLog(@"%@",@"press_end");
        if (_isEndTime) {
            return;
        }
        [self.progerssView endAnimation];
        if (_block) {
            _block(CAPTURE_RECORD_END);
        }
    }
}

-(void)endOfTimeRecord{
    _isEndTime = YES;
    [self.progerssView endAnimation];
    if (_block) {
        _block(CAPTURE_RECORD_END);
    }
}


@end
