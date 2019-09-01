//
//  WJCameraController.m
//  WJCamera
//
//  Created by wangwenj on 2019/8/14.
//  Copyright © 2019 wangwenj. All rights reserved.
//

#import "WJCameraController.h"
#import "CaptureView.h"
#import "WJUtilDefine.h"
#import "SavaFileALbumUtil.h"

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import "HAVPlayer.h"
#import "UIImage+WJLibrary.h"


typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

API_AVAILABLE(ios(10.0))
@interface WJCameraController ()<AVCaptureFileOutputRecordingDelegate,AVCapturePhotoCaptureDelegate,CAAnimationDelegate>


//负责输入和输出设备之间的数据传递
@property(nonatomic)AVCaptureSession *session;
@property (strong,nonatomic) AVCaptureMovieFileOutput*captureMovieFileOutput;//视频输出流
@property (strong,nonatomic) AVCapturePhotoOutput *capturePhotoOutput;//照片输出流
@property (strong,nonatomic) AVCaptureStillImageOutput *captureStillImageOutput;//照片输出流
@property (strong,nonatomic) AVCaptureDeviceInput *captureDeviceInput;//负责从AVCaptureDevice获得输入数据
@property (strong,nonatomic) AVCaptureDeviceInput* audioCaptureDeviceInput;//音频输入数据


//图像预览层，实时显示捕获的图像
@property(nonatomic)AVCaptureVideoPreviewLayer *previewLayer;

//后台任务标识
@property (assign,nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (assign,nonatomic) UIBackgroundTaskIdentifier lastBackgroundTaskIdentifier;

@property (strong,nonatomic) UITapGestureRecognizer *recognizerFocusing;

@property(strong, nonatomic)CaptureView *captureView;  // 拍照按钮
@property (assign, nonatomic) CGPoint captureCenter;
@property (strong,nonatomic)UIView *priviewBg;  // 镜头预览
@property (assign, nonatomic) BOOL isFocus;
@property (strong, nonatomic) UIImageView *focusCursor; //聚焦光标

@property (strong, nonatomic) UIButton *btnBack;
@property (strong, nonatomic) UIButton *btnConfirm;
@property (strong, nonatomic) UIButton *btnRephotography;

@property (strong, nonatomic) UIButton *btnChangeCamera;


@property (strong, nonatomic) UIImageView *priviewImageView; //图片预览

@property (strong, nonatomic) HAVPlayer *player; //视频预览
@property (strong, nonatomic) AVPlayerItem *videoItem;

@property (strong, nonatomic) UIVisualEffectView *effectView; //毛玻璃效果

@property (strong, nonatomic) UIImage *completedImg;

@property (strong, nonatomic) NSURL *completedVideoUrl;


@end

@implementation WJCameraController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColor.clearColor;

    [self setupSubView];
    [self customCamera];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.session startRunning];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.session stopRunning];
}

-(void)setupSubView{
    _priviewBg = [[UIView alloc] initWithFrame:self.view.bounds];
    _priviewBg.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_priviewBg];
    
    _priviewImageView = [[UIImageView alloc]initWithFrame:self.view.bounds];
    [self.view insertSubview:_priviewImageView aboveSubview:_priviewBg];
    _priviewImageView.hidden = TRUE;
    
    // 对焦
    self.focusCursor = [[UIImageView alloc]initWithFrame:CGRectMake(100, 100, 60,60)];
    [self.view addSubview:self.focusCursor];
   
    self.focusCursor.image = [UIImage wj_bundleImageNamed:@"focusing"];
    [self onHiddenFocusCurSorAction];
    
    _captureCenter = CGPointMake(VIEW_W(self.view)/2, VIEW_H(self.view)-60);
    
    _captureView = [[CaptureView alloc]initWithFrame:CGRectMake(0,0, 70, 70)];
    _captureView.center = _captureCenter;
    [self.view addSubview:_captureView];
    
    //切换摄像头
    _btnChangeCamera = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnChangeCamera.frame = CGRectMake(VIEW_W(self.view) - 60, 20 , 46 , 46);
    [_btnChangeCamera setImage: [UIImage wj_bundleImageNamed:@"btn_video_flip_camera"] forState:UIControlStateNormal];
    [self.view addSubview: _btnChangeCamera];
    [_btnChangeCamera addTarget:self action:@selector(changeCamera:) forControlEvents:UIControlEventTouchUpInside];
    
    WS(weakSelf);
    _captureView.block = ^(CaptureAction action) {
        switch (action) {
            case CAPTURE_TAKE_PIC:
                //拍照
                [weakSelf takePic];
                break;
            case CAPTURE_RECORD_START:
                //开始录像
                [weakSelf beginRecode];
                break;
            case CAPTURE_RECORD_END:
                //结束录像
                [weakSelf.captureMovieFileOutput stopRecording];
                break;
            default:
                break;
        }
    };
    
    //取消拍摄
    _btnBack = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnBack setImage:[UIImage wj_bundleImageNamed:@"wjc_back"] forState:UIControlStateNormal];
    _btnBack.frame = CGRectMake(0, 0, 46, 46);
    _btnBack.center = CGPointMake(_captureCenter.x/2, _captureCenter.y);
    [self.view addSubview:_btnBack];
    [_btnBack addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
    
    _btnRephotography = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnRephotography setImage:[UIImage wj_bundleImageNamed:@"take_cancle"] forState:UIControlStateNormal];
    _btnRephotography.frame = CGRectMake(0, 0, 46, 46);
    _btnRephotography.center = _captureCenter;
    [self.view insertSubview:_btnRephotography  belowSubview:_captureView];
    [_btnRephotography addTarget:self action:@selector(rephotography:) forControlEvents:UIControlEventTouchUpInside];
    _btnRephotography.hidden = TRUE;
    
    _btnConfirm = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnConfirm setImage:[UIImage wj_bundleImageNamed:@"take_confirm"] forState:UIControlStateNormal];
    _btnConfirm.frame = CGRectMake(0, 0, 46, 46);
    _btnConfirm.center = _captureCenter;
    [self.view insertSubview:_btnConfirm belowSubview:_captureView];
    [_btnConfirm addTarget:self action:@selector(confirm:) forControlEvents:UIControlEventTouchUpInside];
    _btnConfirm.hidden = TRUE;
}

-(void)customCamera{
    //初始化会话，用来结合输入输出
    self.session = [[AVCaptureSession alloc] init];
    //设置分辨率 (设备支持的最高分辨率)
    if ([self.session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        self.session.sessionPreset = AVCaptureSessionPresetHigh;
    }
    //取得输入涉笔后置摄像头
    AVCaptureDevice *captureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
    //音频输入设备
    AVCaptureDevice *audioCaptureDevice=[[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    //初始化输入设备
    NSError *error = nil;
    self.captureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
    if (error) {
        NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    //添加音频
    error = nil;
    self.audioCaptureDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:audioCaptureDevice error:&error];
    if (error) {
        NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    //输出对象
    //拍照
    if (@available(iOS 10.0, *)) {
        self.capturePhotoOutput = [AVCapturePhotoOutput new];
        if ([self.session canAddOutput:self.capturePhotoOutput]) {
            [self.session addOutput:self.capturePhotoOutput];
        }
    } else {
        // Fallback on earlier versions
        self.captureStillImageOutput = [AVCaptureStillImageOutput new];
        if ([self.session canAddOutput:self.captureStillImageOutput]) {
            [self.session addOutput:self.captureStillImageOutput];
        }
    }
    
    //视频输出
    self.captureMovieFileOutput = [AVCaptureMovieFileOutput new];
    if ([self.session canAddInput:self.audioCaptureDeviceInput]) {
        [self.session addInput:self.audioCaptureDeviceInput];
    }
    
    //将输入设备添加到会话
    if ([self.session canAddInput:self.captureDeviceInput]) {
        [self.session addInput:self.captureDeviceInput];
        //设置视频防抖
        AVCaptureConnection *connection = [self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([connection isVideoStabilizationSupported]) {
            connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeCinematic;
        }
    }
    //将输出设备添加到会话 (刚开始 是照片为输出对象)
    if ([self.session canAddOutput:self.captureMovieFileOutput]) {
        [self.session addOutput:self.captureMovieFileOutput];
    }
    
    //预览层，用于实时展示摄像头状态
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;//填充模式
    CALayer *layer = _priviewBg.layer;
    layer.masksToBounds = YES;
    self.previewLayer.frame = layer.bounds;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [layer insertSublayer:self.previewLayer above:self.focusCursor.layer];
    [self addGenstureRecognizer];
}


-(void)resetView{
    _captureView.hidden = NO;
    [_captureView reset];
    _btnBack.hidden = NO;
    _btnConfirm.hidden = YES;
    _btnRephotography.hidden = YES;
    _recognizerFocusing.enabled = YES;
    _priviewImageView.hidden = YES;
    if (self.player) {
        [self.player stopPlayer];
        self.player.hidden = YES;
    }
    _completedImg = nil;
    _completedVideoUrl = nil;
}

-(void)takeCompletion{
    // 保存
    if (_completedImg) {
        [self saveImageToAsset:_completedImg];
    }else if(_completedVideoUrl){
        [self saveToAsset:_completedVideoUrl];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)back:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)rephotography:(id)sender{
    [self resetView];
}

-(void)confirm:(id)sender{
    [self takeCompletion];
}



-(void)takePic{
    if (@available(iOS 10.0, *)) {
        AVCaptureConnection *connection = [self.captureStillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        if (connection.isVideoOrientationSupported) {
            connection.videoOrientation = [self.previewLayer connection].videoOrientation;
        }
        [self.capturePhotoOutput capturePhotoWithSettings:[AVCapturePhotoSettings photoSettings] delegate:self];
    }else{
        AVCaptureConnection *connection = [self.captureStillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        if (connection.isVideoOrientationSupported) {
            connection.videoOrientation = [self.previewLayer connection].videoOrientation;
        }
        WS(weakSelf);
        id takePicture = ^(CMSampleBufferRef sampleBuffer,NSError *error){
            if (sampleBuffer == NULL) {
                return ;
            }
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:sampleBuffer];
            UIImage *image = [[UIImage alloc]initWithData:imageData];
            [weakSelf takePictureSuccess:image];
        };
        [self.captureStillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:takePicture];
    }
}

-(void)takePictureSuccess:(UIImage *)image{
    _priviewImageView.hidden = NO;
    _priviewImageView.image = image;
    _completedImg = image;
    [self takeSuccessView];
}

-(void)takeVideoSuccess:(NSURL*)videoURL{
    _completedVideoUrl = videoURL;
    if (!self.player) {
        self.player = [[HAVPlayer alloc] initWithFrame:self.priviewBg.bounds withShowInView:self.priviewBg url:videoURL];
    } else {
        if (videoURL) {
            self.player.videoUrl = videoURL;
            self.player.hidden = NO;
        }
    }
    [self takeSuccessView];
}

-(void)takeSuccessView{
    _captureView.hidden = YES;
    _btnBack.hidden = YES;
    _btnConfirm.hidden = NO;
    _btnRephotography.hidden = NO;
    _recognizerFocusing.enabled = NO;
    _btnRephotography.center = _captureCenter;
    _btnConfirm.center = _captureCenter;
    WS(weakSelf);
    [UIView animateWithDuration:0.25 animations:^{
        weakSelf.btnRephotography.center = CGPointMake(weakSelf.captureCenter.x/2, weakSelf.captureCenter.y);
        weakSelf.btnConfirm.center = CGPointMake(weakSelf.captureCenter.x/2 * 3, weakSelf.captureCenter.y);
    }];
}

-(void)beginRecode{
    AVCaptureConnection *connection = [self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeAudio];
    if (![self.captureMovieFileOutput isRecording]) {
        if ([[UIDevice currentDevice] isMultitaskingSupported]) {
            self.backgroundTaskIdentifier = [[UIApplication sharedApplication]beginBackgroundTaskWithExpirationHandler:^{
            }];
        }
        connection.videoOrientation = [self.previewLayer connection].videoOrientation;
        NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
        NSString *filePath = [NSTemporaryDirectory() stringByAppendingString:[NSString stringWithFormat:@"av%lf.mov",interval]];
        [self.captureMovieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:filePath] recordingDelegate:self];
    }
}


-(void)changeCamera:(id)sender{
    AVCaptureDevice *currentDevice=[self.captureDeviceInput device];
    AVCaptureDevicePosition currentPosition=[currentDevice position];
    AVCaptureDevice *toChangeDevice;
    AVCaptureDevicePosition toChangePosition = AVCaptureDevicePositionFront;//前
    if (currentPosition == AVCaptureDevicePositionUnspecified || currentPosition == AVCaptureDevicePositionFront) {
        toChangePosition = AVCaptureDevicePositionBack;//后
    }
    toChangeDevice=[self getCameraDeviceWithPosition:toChangePosition];
    //获得要调整的设备输入对象
    AVCaptureDeviceInput *toChangeDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:toChangeDevice error:nil];
    
    //改变会话的配置前一定要先开启配置，配置完成后提交配置改变
    [self.session beginConfiguration];
    //移除原有输入对象
    [self.session removeInput:self.captureDeviceInput];
    //添加新的输入对象
    if ([self.session canAddInput:toChangeDeviceInput]) {
        [self.session addInput:toChangeDeviceInput];
        self.captureDeviceInput = toChangeDeviceInput;
    }
    //提交会话配置
    [self.session commitConfiguration];
    //1 创建动画对象
    CATransition *trans = [CATransition animation];
    //2 设置动画属性
    trans.duration = 0.25;
    trans.repeatCount = 0;
    //3 设置动画效果（翻转效果）
    trans.type = @"oglFlip";
    trans.subtype = @"fromRight";
    trans.delegate = self;
    //4 开始动画
    [self.previewLayer addAnimation:trans forKey:nil];
}


-(UIVisualEffectView *)effectView{
    if (!_effectView) {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _effectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        _effectView.frame = _priviewBg.bounds;
    }
    return _effectView;
}
#pragma mark --CAAnimationDelegate--

- (void)animationDidStart:(CAAnimation *)anim{
    [self.priviewBg addSubview:self.effectView];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    [self.effectView removeFromSuperview];
}

/**
 *  取得指定位置的摄像头
 *
 *  @param position 摄像头位置
 *
 *  @return 摄像头设备
 */
-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position] == position) {
            return camera;
        }
    }
    return nil;
}

#pragma mark --AVCapturePhotoCaptureDelegate--
-(void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error API_AVAILABLE(ios(11.0)){
    NSData *imgDate = nil;
    if (@available(iOS 11.0, *)) {
        imgDate = [photo fileDataRepresentation];
    } else {
        // Fallback on earlier versions
    }
    UIImage *image = [[UIImage alloc]initWithData:imgDate];
    [self takePictureSuccess:image];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhotoSampleBuffer:(nullable CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(nullable CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(nullable AVCaptureBracketedStillImageSettings *)bracketSettings error:(nullable NSError *)error API_DEPRECATED("Use -captureOutput:didFinishProcessingPhoto:error: instead.", ios(10.0, 11.0)){
    
    UIImage *image = [self imageConvert:photoSampleBuffer];
    [self takePictureSuccess:image];
}

//CMSampleBufferRef=>UIImage
- (UIImage *)imageConvert:(CMSampleBufferRef)sampleBuffer
{
    
    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // 得到pixel buffer的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // 得到pixel buffer的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到pixel buffer的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // 释放context和颜色空间
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // 用Quartz image创建一个UIImage对象image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // 释放Quartz image对象
    CGImageRelease(quartzImage);
    
    return (image);
}

#pragma mark --AVCaptureFileOutputRecordingDelegate--
-(void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections{
    
}

-(void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(NSError *)error{
    //[self saveToAsset:outputFileURL];
    [self takeVideoSuccess:outputFileURL];
   
}

-(void)saveToAsset:(NSURL *)localURL{
    WS(weakSelf);
    [SavaFileALbumUtil saveFilePaths:@[localURL] forVc:self complete:^(NSArray<PHAsset *> * _Nonnull result) {
        [weakSelf.delegate completeWithAsset:result[0] image:nil videoPath:localURL];
    }];
}

-(void)saveImageToAsset:(UIImage*)image{
    WS(weakSelf);
    [SavaFileALbumUtil saveImages:@[image] forVc:self complete:^(NSArray<PHAsset *> * _Nonnull result) {
        [weakSelf.delegate completeWithAsset:result[0] image:image videoPath:nil];
    }];
}

/**
 *  改变设备属性的统一操作方法
 *
 *  @param propertyChange 属性改变操作
 */
-(void)changeDeviceProperty:(PropertyChangeBlock)propertyChange{
    AVCaptureDevice *captureDevice= [self.captureDeviceInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        //自动白平衡
        if ([captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
            [captureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
        }
        //自动根据环境条件开启闪光灯
        if ([captureDevice isFlashModeSupported:AVCaptureFlashModeAuto]) {
            [captureDevice setFlashMode:AVCaptureFlashModeAuto];
        }
        
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}


#pragma mark --对焦--

-(void)addGenstureRecognizer{
    UITapGestureRecognizer *tapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapScreen:)];
    [self.view addGestureRecognizer:tapGesture];
    _recognizerFocusing = tapGesture;
}

-(void)tapScreen:(UITapGestureRecognizer *)tapGesture{
    if ([self.session isRunning]) {
        CGPoint point= [tapGesture locationInView:self.view];
        //将UI坐标转化为摄像头坐标
        CGPoint cameraPoint= [self.previewLayer captureDevicePointOfInterestForPoint:point];
        [self setFocusCursorWithPoint:point];
        [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposureMode:AVCaptureExposureModeContinuousAutoExposure atPoint:cameraPoint];
    }
}

/**
 *  设置聚焦光标位置
 *
 *  @param point 光标位置
 */
-(void)setFocusCursorWithPoint:(CGPoint)point{
    if (!self.isFocus) {
        self.isFocus = YES;
        self.focusCursor.center=point;
        self.focusCursor.transform = CGAffineTransformMakeScale(1.25, 1.25);
        self.focusCursor.alpha = 1.0;
        [UIView animateWithDuration:0.5 animations:^{
            self.focusCursor.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            [self performSelector:@selector(onHiddenFocusCurSorAction) withObject:nil afterDelay:0.5];
        }];
    }
}

-(void)onHiddenFocusCurSorAction{
    self.focusCursor.alpha=0;
    self.isFocus = NO;
}

/**
 *  设置聚焦点
 *
 *  @param point 聚焦点
 */
-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:exposureMode];
        }
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:focusMode];
        }
    }];
}

@end
