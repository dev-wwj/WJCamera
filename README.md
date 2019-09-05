# WJCamera

[![CI Status](https://img.shields.io/travis/scorpion/WJCamera.svg?style=flat)](https://travis-ci.org/scorpion/WJCamera)
[![Version](https://img.shields.io/cocoapods/v/WJCamera.svg?style=flat)](https://cocoapods.org/pods/WJCamera)
[![License](https://img.shields.io/cocoapods/l/WJCamera.svg?style=flat)](https://cocoapods.org/pods/WJCamera)
[![Platform](https://img.shields.io/cocoapods/p/WJCamera.svg?style=flat)](https://cocoapods.org/pods/WJCamera)

iOS相机
点击拍照，长按录像

## Example

#import "WJCameraController.h"


//创建

WJCameraController *wjc =[[WJCameraController alloc] init];

wjc.delegate = self;

[self presentViewController:wjc animated:YES completion:nil];


//通过delegate，得到拍摄的照片或视频.

-(void)completeWithAsset:(PHAsset*)asset image:(UIImage *)image videoPath:(NSURL*)videoPath{
}

## Requirements

## Installation

WJCamera is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'WJCamera'
```

## Author

scorpion, 747833020@qq.com

## License

WJCamera is available under the MIT license. See the LICENSE file for more info.
