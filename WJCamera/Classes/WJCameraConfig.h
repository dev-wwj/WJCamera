//
//  WJCameraConfig.h
//  Expecta
//
//  Created by 王文建 on 2019/9/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSInteger, CAMERA_TAKE_MODE) {
    ALL = 0,
    PHOTO = 1 << 0,
    VIDOE = 2 << 1
    
};

@interface WJCameraConfig : NSObject
@property(assign, nonatomic) NSInteger Max_time; //最长录制时长
@property(assign, nonatomic) CAMERA_TAKE_MODE takeMode;

+(instancetype)config;

@end

NS_ASSUME_NONNULL_END
