#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "CaptureView.h"
#import "HAVPlayer.h"
#import "NSBundle+WJLibrary.h"
#import "SavaFileALbumUtil.h"
#import "UIImage+WJLibrary.h"
#import "WJCameraConfig.h"
#import "WJCameraController.h"
#import "WJProgressView.h"
#import "WJShootButton.h"
#import "WJUtilDefine.h"

FOUNDATION_EXPORT double WJCameraVersionNumber;
FOUNDATION_EXPORT const unsigned char WJCameraVersionString[];

