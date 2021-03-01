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

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import "HAVPlayer.h"
#import "UIImage+WJLibrary.h"


typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

API_AVAILABLE(ios(10.0))
@interface WJCameraController ()<AVCaptureFileOutputRecordingDelegate,AVCapturePhotoCaptureDelegate,CAAnimationDelegate,UIGestureRecognizerDelegate> {
    dispatch_queue_t _sessonQueen;
}


//负责输入和输出设备之间的数据传递
@property(nonatomic)AVCaptureSession *session;
@property (strong,nonatomic) AVCaptureDeviceInput *captureDeviceInput;//负责从AVCaptureDevice获得输入数据
@property (strong,nonatomic) AVCaptureDeviceInput* audioCaptureDeviceInput;//音频输入数据
@property (strong,nonatomic) AVCaptureMovieFileOutput*captureMovieFileOutput;//视频输出流
@property (strong,nonatomic) AVCapturePhotoOutput *capturePhotoOutput;//照片输出流

//图像预览层，实时显示捕获的图像
@property(strong,nonatomic)AVCaptureVideoPreviewLayer *previewLayer;

@property (strong,nonatomic) UITapGestureRecognizer *recognizerFocusing;

@property (strong, nonatomic) UIView *safeArea;
@property(strong, nonatomic)  CaptureView *captureView;  // 拍照按钮

@property (strong,nonatomic)UIView *previewBg;  // 镜头预览
@property (assign, nonatomic) BOOL isFocus;
@property (strong, nonatomic) UIImageView *focusCursor; //聚焦光标

@property (strong, nonatomic) UIButton *btnBack;

@property (strong, nonatomic) UIButton *btnConfirm, *btnCancle;  // 完成｜取消

@property (strong, nonatomic) NSLayoutConstraint *confirmCenterYConstration, *cancleCenterYCanstration;

@property (strong, nonatomic) UIButton *btnChangeCamera;

@property (strong, nonatomic) UIImageView *previewImageView; //图片预览

@property (strong, nonatomic) HAVPlayer *player; //视频预览
@property (strong, nonatomic) AVPlayerItem *videoItem;

@property (strong, nonatomic) UIVisualEffectView *effectView; //毛玻璃效果

@property (strong, nonatomic) UIImage *completedImg;

@property (strong, nonatomic) NSURL *completedVideoUrl;

@property(nonatomic, copy) AVCaptureSessionPreset sessionPreset;  // 设置录像分辨率

@property(strong, nonatomic) CADisplayLink *displayLink;

@property (assign, nonatomic) CFTimeInterval beginTime;

@end

@implementation WJCameraController

- (instancetype _Nullable )initWithTakeMode:(CAMERA_TAKE_MODE) takeMode delegate:(id<CameraDelegate>_Nullable)delegate {
    self = [super init];
    if (self) {
        self.minDuration = 3.0;
        self.maxDuration = 15.0;
        self.takeMode = takeMode;
        self.delegate = delegate;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColor.clearColor;

    [self setupSubView];
    [self setupCamera];
}

- (void)viewSafeAreaInsetsDidChange{
    [super viewSafeAreaInsetsDidChange];
    
    [self.view addConstraints:[NSLayoutConstraint  constraintsWithVisualFormat:@"H:|[view]|" options:kNilOptions metrics:nil views:@{@"view":_safeArea}]];

    if (@available(iOS 11.0, *)) {
        [self.view addConstraints:[NSLayoutConstraint  constraintsWithVisualFormat:@"V:|-Top-[view]-Bottom-|" options:kNilOptions metrics:@{@"Top":@(self.view.safeAreaInsets.top),@"Bottom":@(self.view.safeAreaInsets.bottom)} views:@{@"view":_safeArea}]];
    } else {
        [self.view addConstraints:[NSLayoutConstraint  constraintsWithVisualFormat:@"V:|-24-[view]-0-|" options:kNilOptions metrics:nil views:@{@"view":_safeArea}]];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.session startRunning];
    [self startPreview];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.session stopRunning];
}


-(void)setupSubView{
    self.view.backgroundColor = UIColor.blackColor;
    
    _safeArea = [[UIView alloc]init];
    _safeArea.translatesAutoresizingMaskIntoConstraints = NO;
    _safeArea.backgroundColor = UIColor.clearColor;
    [self.view addSubview:_safeArea];
    
    _previewBg = [[UIView alloc] init];
    _previewBg.translatesAutoresizingMaskIntoConstraints = NO;
    _previewBg.backgroundColor = [UIColor blackColor];
    [_safeArea addSubview:_previewBg];
    [_safeArea addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:kNilOptions metrics:nil views:@{@"view":_previewBg}]];
    [_safeArea addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-top-[view]-bottom-|" options:kNilOptions metrics:@{@"top":@(44),@"bottom":@(100)} views:@{@"view":_previewBg}]];
    
    _previewImageView = [[UIImageView alloc]init];
    _previewImageView.contentMode = UIViewContentModeScaleAspectFit;
    _previewImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [_previewBg addSubview:_previewImageView];
    _previewImageView.hidden = YES;
    [_previewBg addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:kNilOptions metrics:nil views:@{@"view":_previewImageView}]];
    [_previewBg addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:kNilOptions metrics:nil views:@{@"view":_previewImageView}]];
    
    // 对焦
    _focusCursor = [[UIImageView alloc]initWithFrame:CGRectMake(100, 100, 60,60)];
    [_previewBg addSubview:_focusCursor];
    _focusCursor.image = [UIImage wj_bundleImageNamed:@"focusing"];
    [self onHiddenFocusCurSorAction];
    
    [self addGenstureRecognizer];

    _captureView = [[CaptureView alloc]init];
    _captureView.progressColor = _progressColor ?: UIColor.brownColor;
    _captureView.translatesAutoresizingMaskIntoConstraints = NO;
    [_safeArea addSubview:_captureView];
    [_safeArea addConstraint:[NSLayoutConstraint constraintWithItem:_captureView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_safeArea attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    [_safeArea addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[view(88)]" options:kNilOptions metrics:nil views:@{@"view":_captureView}]];
    [_safeArea addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[view(88)]-10-|" options:kNilOptions metrics:nil views:@{@"view":_captureView}]];
    WS(weakSelf);
    _captureView.block = ^(CaptureAction action) {
        switch (action) {
            case Tap:
                //拍照
                [weakSelf shoot];
                break;
            case LongPress:
                //开始录像
                [weakSelf beginRecode];
                break;
            case EndLongPress:
                //结束录像
                [weakSelf endRecode];
                break;
            default:
                break;
        }
    };
    
    //切换摄像头
    _btnChangeCamera = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnChangeCamera.translatesAutoresizingMaskIntoConstraints = NO;
    [_btnChangeCamera setImage: [UIImage wj_bundleImageNamed:@"btn_video_flip_camera"] forState:UIControlStateNormal];
    [_btnChangeCamera addTarget:self action:@selector(changeCamera:) forControlEvents:UIControlEventTouchUpInside];
    [_safeArea addSubview: _btnChangeCamera];
    [_safeArea addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[view(44)]-10-|" options:kNilOptions metrics:nil views:@{@"view":_btnChangeCamera}]];
    [_safeArea addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view(44)]" options:kNilOptions metrics:nil views:@{@"view":_btnChangeCamera}]];
    
    //取消拍摄
    _btnBack = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnBack.translatesAutoresizingMaskIntoConstraints = NO;
    [_btnBack setImage:[UIImage wj_bundleImageNamed:@"wjc_back"] forState:UIControlStateNormal];
    [_btnBack addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
    [_safeArea addSubview:_btnBack];
    [_safeArea addConstraint:[NSLayoutConstraint constraintWithItem:_btnBack attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_captureView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    [_safeArea addConstraint:[NSLayoutConstraint constraintWithItem:_btnBack attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_safeArea attribute:NSLayoutAttributeCenterX multiplier:0.5 constant:0.0]];
    [_btnBack setEnlargeEdge:44];
    
    _btnCancle = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnCancle setImage:[UIImage wj_bundleImageNamed:@"take_cancle"] forState:UIControlStateNormal];
    [_btnCancle addTarget:self action:@selector(rephotography:) forControlEvents:UIControlEventTouchUpInside];
    [_safeArea insertSubview:_btnCancle  belowSubview:_captureView];
    _btnCancle.alpha = 0.0;
    _btnCancle.translatesAutoresizingMaskIntoConstraints = NO;
    [_safeArea addConstraint:[NSLayoutConstraint constraintWithItem:_btnCancle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_captureView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    
    _btnConfirm = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnConfirm setImage:[UIImage wj_bundleImageNamed:@"take_confirm"] forState:UIControlStateNormal];
    [_btnConfirm addTarget:self action:@selector(confirm:) forControlEvents:UIControlEventTouchUpInside];
    [_safeArea insertSubview:_btnConfirm belowSubview:_captureView];
    _btnConfirm.alpha = 0.0;
    _btnConfirm.translatesAutoresizingMaskIntoConstraints = NO;
    [_safeArea addConstraint:[NSLayoutConstraint constraintWithItem:_btnConfirm attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_captureView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    [self updateSafeAreaConstraintsWithComplete:NO];
}

- (void)updateSafeAreaConstraintsWithComplete:(BOOL)complate {
    if (_confirmCenterYConstration) {
        [_safeArea removeConstraint:_confirmCenterYConstration];
        _confirmCenterYConstration = nil;
    }
    if (_cancleCenterYCanstration) {
        [_safeArea removeConstraint:_cancleCenterYCanstration];
        _cancleCenterYCanstration = nil;
    }
    if (!complate) {
        _cancleCenterYCanstration = [NSLayoutConstraint constraintWithItem:_btnCancle attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_captureView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
        _confirmCenterYConstration = [NSLayoutConstraint constraintWithItem:_btnConfirm attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_captureView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    }else {
        _cancleCenterYCanstration = [NSLayoutConstraint constraintWithItem:_btnCancle attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_captureView attribute:NSLayoutAttributeCenterX multiplier:0.5 constant:0.0];
        _confirmCenterYConstration = [NSLayoutConstraint constraintWithItem:_btnConfirm attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_captureView attribute:NSLayoutAttributeCenterX multiplier:1.5 constant:0.0];
    }
    [_safeArea addConstraints:@[_cancleCenterYCanstration,_confirmCenterYConstration]];
    [_safeArea updateConstraintsIfNeeded];
}

-(void)setupCamera{
    //取得输入设备后置摄像头
    AVCaptureDevice *captureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
    //音频输入设备
    AVCaptureDevice *audioCaptureDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    //初始化输入设备
    NSError *error = nil;
    self.captureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
    if (error) {
        NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    if ([self.session canAddInput:self.captureDeviceInput]) {
        [self.session addInput:self.captureDeviceInput];
    }
    
    //添加音频
    error = nil;
    self.audioCaptureDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:audioCaptureDevice error:&error];
    if (error) {
        NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    
    if ([self.session canAddInput:self.audioCaptureDeviceInput]) {
        [self.session addInput:self.audioCaptureDeviceInput];
    }
    [self.session setSessionPreset:_previewSessionPreset?:AVCaptureSessionPresetHigh];
    [self capturePhotoOutput];
    [self captureMovieFileOutput];
}

//初始化会话，用来结合输入输出
- (AVCaptureSession *)session {
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
    }
    return _session;
}

// 设置输出分辨率
- (void)setSessionPreset:(AVCaptureSessionPreset)sessionPreset {
    _sessionPreset = sessionPreset;
    if ([self.session canSetSessionPreset:sessionPreset]) {
        self.session.sessionPreset = AVCaptureSessionPresetPhoto;
    }else {
        NSLog(@"设备不支持此分辨率");
    }
}

//输出对象
//拍照
- (AVCapturePhotoOutput *)capturePhotoOutput API_AVAILABLE(ios(10.0)){
    if (!_capturePhotoOutput) {
        _capturePhotoOutput = [AVCapturePhotoOutput new];
        if ([self.session canAddOutput:_capturePhotoOutput]) {
            [self.session addOutput:_capturePhotoOutput];
        }
    }
    return _capturePhotoOutput;
}

//视频
- (AVCaptureMovieFileOutput *)captureMovieFileOutput {
    if (!_captureMovieFileOutput) {
        _captureMovieFileOutput = [AVCaptureMovieFileOutput new];
        if ([self.session canAddOutput:_captureMovieFileOutput]) {
            [self.session addOutput:_captureMovieFileOutput];
        }
        //设置视频防抖
        AVCaptureConnection * captureCollection = [_captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([captureCollection isVideoStabilizationSupported]) {
            captureCollection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeCinematic;
        }
    }
    return _captureMovieFileOutput;
}


- (void)startPreview {
    [self previewLayer];
}

//预览层，用于实时展示摄像头状态
- (AVCaptureVideoPreviewLayer*)previewLayer {
    if (!_previewLayer) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;//填充模式
        CALayer *layer = _previewBg.layer;
        layer.masksToBounds = YES;
        _previewLayer.frame = layer.bounds;
        [layer insertSublayer:_previewLayer below:self.focusCursor.layer];
    }
    return _previewLayer;
}


- (void)setTakeMode:(CAMERA_TAKE_MODE)takeMode{
    _takeMode = takeMode;
}

-(void)takeCompletion{
//    保存
//    if (_completedImg) {
//        [self saveImageToAsset:_completedImg];
//    }else if(_completedVideoUrl){
//        [self saveToAsset:_completedVideoUrl];
//    }
}

-(void)back:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)rephotography:(id)sender{
    [self resetView];
}

-(void)confirm:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)shoot{
    [self.capturePhotoOutput connectionWithMediaType:AVMediaTypeVideo].videoMirrored = [self.captureDeviceInput device].position == AVCaptureDevicePositionFront;
    [self.capturePhotoOutput capturePhotoWithSettings:[AVCapturePhotoSettings photoSettings] delegate:self];
}

-(void)shootSuccess:(UIImage *)image{
    if ([_delegate respondsToSelector:@selector(takePhotoComplete:)]) {
        [_delegate takePhotoComplete:image];
    }
    _previewImageView.hidden = NO;
    _previewImageView.image = image;
    [self completeView];
}

-(void)resetView{
    self.previewLayer.hidden = NO;
    _btnChangeCamera.hidden = NO;
    _btnBack.hidden = NO;
    _recognizerFocusing.enabled = YES;
    _previewImageView.hidden = YES;
    if (self.player) {
        [self.player stopPlayer];
        self.player.hidden = YES;
    }
    _completedImg = nil;
    _completedVideoUrl = nil;
    
    [self updateSafeAreaConstraintsWithComplete:NO];
    [UIView animateWithDuration:0.25 animations:^{
        self->_captureView.alpha = 1.0;
        self->_btnConfirm.alpha = 0.0;
        self->_btnCancle.alpha = 0.0;
        self->_captureView.progress = 0.0;
        [self->_safeArea layoutIfNeeded];
    } completion:^(BOOL finished) {
    }];
}

-(void)completeView{
    self.previewLayer.hidden = YES;
    _btnChangeCamera.hidden = YES;
    _btnBack.hidden = YES;
    _recognizerFocusing.enabled = NO;
    [self updateSafeAreaConstraintsWithComplete:YES];
    [UIView animateWithDuration:0.25 animations:^{
        self->_captureView.alpha = 0.0;
        self->_btnConfirm.alpha = 1.0;
        self->_btnCancle.alpha = 1.0;
        [self->_safeArea layoutIfNeeded];
    } completion:^(BOOL finished) {
        self->_captureView.progress = 0.0;
    }];
}

- (void)recodingView {
    _btnChangeCamera.hidden = YES;
    _btnBack.hidden = YES;
}

// 录制
-(void)beginRecode{
    if (![self.captureMovieFileOutput isRecording]) {
        [self recodingView];
        AVCaptureConnection * captureCollection = [self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        captureCollection.videoMirrored = [self.captureDeviceInput device].position == AVCaptureDevicePositionFront;
        NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
        NSString *filePath = [NSTemporaryDirectory() stringByAppendingString:[NSString stringWithFormat:@"av%.0f.mov",interval]];
        [self.captureMovieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:filePath] recordingDelegate:self];
        [self startProgress];
    }
}

- (void)endRecode {
    [_captureMovieFileOutput stopRecording];
    [self endProgress];
}

-(void)recodeSuccess:(NSURL*)videoURL{
    _completedVideoUrl = videoURL;
    AVURLAsset *asset = [AVURLAsset assetWithURL:videoURL];
    CMTime  time = [asset duration];
    float duration =  (float)time.value / time.timescale;
    if (duration < _minDuration) {
        if ([_delegate respondsToSelector:@selector(recordLessMinDuration)] ) {
            [_delegate recordLessMinDuration];
        }
        [self resetView];
    }else {
        if ([_delegate respondsToSelector:@selector(recodeVideoComplete:)] ) {
            [_delegate recodeVideoComplete:videoURL];
        }
        if (!self.player) {
            self.player = [[HAVPlayer alloc] initWithFrame:self.previewBg.bounds withShowInView:self.previewBg url:videoURL];
        } else {
            if (videoURL) {
                self.player.videoUrl = videoURL;
                self.player.hidden = NO;
            }
        }
        [self completeView];
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
    [self.session commitConfiguration];
    //提交会话配置
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
        _effectView.frame = _previewBg.bounds;
    }
    return _effectView;
}
#pragma mark --CAAnimationDelegate--

- (void)animationDidStart:(CAAnimation *)anim{
    [self.previewBg addSubview:self.effectView];
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
    [self shootSuccess:image];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhotoSampleBuffer:(nullable CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(nullable CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(nullable AVCaptureBracketedStillImageSettings *)bracketSettings error:(nullable NSError *)error API_DEPRECATED("Use -captureOutput:didFinishProcessingPhoto:error: instead.", ios(10.0, 11.0)){
    UIImage *image = [UIImage imageWithSampleBuffer:photoSampleBuffer];
    [self shootSuccess:image];
}


#pragma mark --AVCaptureFileOutputRecordingDelegate--
-(void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections{
    
}

-(void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(NSError *)error{
    [self recodeSuccess:outputFileURL];
}

#pragma mark -- 保存 ---
//-(void)saveToAsset:(NSURL *)localURL{
//    WS(weakSelf);
//    [SavaFileALbumUtil saveFilePaths:@[localURL] forVc:self complete:^(NSArray<PHAsset *> * _Nonnull result) {
//        [weakSelf.delegate completeWithAsset:result[0] image:nil videoPath:localURL];
//    }];
//}
//
//-(void)saveImageToAsset:(UIImage*)image{
//    WS(weakSelf);
//    [SavaFileALbumUtil saveImages:@[image] forVc:self complete:^(NSArray<PHAsset *> * _Nonnull result) {
//        [weakSelf.delegate completeWithAsset:result[0] image:image videoPath:nil];
//    }];
//}

#pragma mark --对焦--

-(void)addGenstureRecognizer{
    UITapGestureRecognizer *tapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapScreen:)];
    tapGesture.delegate = self;
    [self.view addGestureRecognizer:tapGesture];
    _recognizerFocusing = tapGesture;
}

-(void)tapScreen:(UITapGestureRecognizer *)tapGesture{
    if ([self.session isRunning]) {
        CGPoint point= [tapGesture locationInView:_previewBg];
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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (_captureView.superview &&[touch.view isDescendantOfView:_captureView] ) {
        return NO;
    }
    return YES;
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

// 定时器
- (CADisplayLink *)displayLink {
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(recodeProgress:)];
    }
    return _displayLink;
}

- (void)startProgress{
    _beginTime = CACurrentMediaTime();
    self.displayLink.paused = NO;
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)endProgress{
    _displayLink.paused = YES;
    [_displayLink invalidate];
    _displayLink = nil;
}

- (void)recodeProgress:(CADisplayLink *)displayLink {
    CFTimeInterval interval =  CACurrentMediaTime();
    double duration = interval - _beginTime;
    if (_maxDuration <= duration) {
        [self endRecode];
    }else {
        _captureView.progress = duration/_maxDuration;
    }
}

@end
