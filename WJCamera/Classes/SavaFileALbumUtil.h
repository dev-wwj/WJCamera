//
//  SavaFileALbumUtil.h
//  TIMChat
//
//  Created by wangwenj on 2019/7/25.
//  Copyright © 2019 AlexiChen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^SavaComplete)(NSArray<PHAsset*> *result);

@interface SavaFileALbumUtil : NSObject

@property(strong,nonatomic)UIViewController *usersVC;

@property(strong,nonatomic)NSMutableArray<NSURL*>*paths;
@property(strong,nonatomic)NSMutableArray<UIImage*>*images;
@property(strong,nonatomic)NSMutableArray<PHAsset*>*source;
@property(copy, nonatomic)SavaComplete sComplete;
+(void)saveFilePaths:(NSArray*)paths forVc:(UIViewController *)vc complete:(SavaComplete)complete; // 保存文件
+(void)saveImages:(NSArray*)images forVc:(UIViewController *)vc complete:(SavaComplete)complete;  // 保存图片
@end

NS_ASSUME_NONNULL_END
