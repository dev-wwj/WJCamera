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

#import "HAVPlayer.h"
#import "NSBundle+WJ.h"
#import "UIButton+Enlarge.h"
#import "UIImage+WJ.h"
#import "WJCameraController.h"
#import "WJCaptureView.h"
#import "WJProgressView.h"
#import "WJUtilDefine.h"

FOUNDATION_EXPORT double WJCameraVersionNumber;
FOUNDATION_EXPORT const unsigned char WJCameraVersionString[];

