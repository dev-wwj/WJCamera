//
//  WJCameraController.h
//  WJCamera
//
//  Created by wangwenj on 2019/8/14.
//  Copyright © 2019 wangwenj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "WJCameraConfig.h"

@protocol CameraDelegate <NSObject>

-(void)completeWithAsset:(PHAsset*)asset image:(UIImage *)image videoPath:(NSURL*)videoPath;

@end

@interface WJCameraController : UIViewController

@property(nonnull,strong,nonatomic)WJCameraConfig *config;
@property(nullable, weak) id <CameraDelegate> delegate;

+(instancetype)buildWithConfig:(WJCameraConfig *)config;
@end

