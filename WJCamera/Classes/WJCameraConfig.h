//
//  WJCameraConfig.h
//  Expecta
//
//  Created by 王文建 on 2019/9/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WJCameraConfig : NSObject
@property(assign, nonatomic) NSInteger Max_time; //最长录制时长

+(instancetype)config;
@end

NS_ASSUME_NONNULL_END
