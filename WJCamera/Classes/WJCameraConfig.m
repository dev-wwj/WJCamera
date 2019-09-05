//
//  WJCameraConfig.m
//  Expecta
//
//  Created by 王文建 on 2019/9/5.
//

#import "WJCameraConfig.h"

@implementation WJCameraConfig

+(instancetype)config{
    WJCameraConfig *config = [[WJCameraConfig alloc]init];
    config.Max_time  = 15;
    return config;
}


@end
