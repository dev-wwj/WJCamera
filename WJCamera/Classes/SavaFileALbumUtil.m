//
//  SavaFileALbumUtil.m
//  TIMChat
//
//  Created by wangwenj on 2019/7/25.
//  Copyright © 2019 AlexiChen. All rights reserved.
//

#import "SavaFileALbumUtil.h"
#import "WJUtilDefine.h"

/// 导入图片状态
typedef NS_ENUM(NSInteger, ImportStates) {
    ImportStatePrepare    = 0, // 准备导入
    ImportStateImporting  = 1, // 导入中
    ImportStateImported   = 2, // 导入成功
};

@interface SavaFileALbumUtil ()

@property (nonatomic, assign) ImportStates state;


#define BundleName [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]
#define BundleDisplayName [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"]
#define ALbumName BundleDisplayName != nil ? BundleDisplayName : BundleName

@end

@implementation SavaFileALbumUtil

+(void)saveFilePaths:(NSArray*)paths forVc:(UIViewController *)vc complete:(SavaComplete)complete{
    SavaFileALbumUtil *util =  [[SavaFileALbumUtil alloc] init];
    util.paths = [paths mutableCopy];
    util.usersVC = vc;
    util.source = [NSMutableArray arrayWithCapacity:128];
    util.sComplete = complete;
    [util applyAlbumAuth];
}

+(void)saveImages:(NSArray*)images forVc:(UIViewController *)vc complete:(SavaComplete)complete{
    SavaFileALbumUtil *util =  [[SavaFileALbumUtil alloc] init];
    util.images = [images mutableCopy];
    util.usersVC = vc;
    util.source = [NSMutableArray arrayWithCapacity:128];
    util.sComplete = complete;
    [util applyAlbumAuth];
}

// 判断相册权限
- (void)applyAlbumAuth{
    /*
     requestAuthorization方法的功能
     1.如果用户还没有做过选择，这个方法就会弹框让用户做出选择
     1> 用户做出选择以后才会回调block
     2.如果用户之前已经做过选择，这个方法就不会再弹框，直接回调block，传递现在的授权状态给block
     */
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        //涉及到UI弹框 GCD到主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (status) {
                    case PHAuthorizationStatusAuthorized: {
                        //  保存图片到相册
                        [self prepareSave];
                        break;
                    }
                    case PHAuthorizationStatusNotDetermined: {
                        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                            // 如果用户选择授权, 则保存图片
                            if (status == PHAuthorizationStatusAuthorized) {
                                [self prepareSave];
                            }
                        }];
                        break;
                    }
                    case PHAuthorizationStatusRestricted: {
//                       [self prepareApplicationOpenSetting];
                        //访问权限受限制, 这个很少见, 如家长模式的限制才会有
                        break;
                    }
                    case PHAuthorizationStatusDenied: {
                        [self prepareApplicationOpenSetting];
                        break;
                    }
                    
                default:
                    break;
            }
        });
    }];
}

-(void)prepareApplicationOpenSetting{
    NSString *message = [NSString stringWithFormat:@"请授权【%@】访问相册",ALbumName];
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *actionCancle = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *actionSure = [UIAlertAction actionWithTitle:@"去授权" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:url];
    }];
    [alertC addAction:actionCancle];
    [alertC addAction:actionSure];
    [_usersVC presentViewController:alertC animated:YES completion:nil];
}

-(void)prepareSave{
    PHPhotoLibrary *library = [PHPhotoLibrary sharedPhotoLibrary];
    
    // 假如外面需要这个 localIdentifier ，可以通过block传出去
    __block NSString *localIdentifier = @"";
    WS(weakSelf);
    // 2. 调用changeblock
    [library performChanges:^{
        NSURL *path = nil;
        if (weakSelf.paths != nil) {
            path = weakSelf.paths[0];
        }
        // 2.1 创建一个相册变动请求
        PHAssetCollectionChangeRequest *collectionRequest = [self getCurrentPhotoCollection];
        PHAssetChangeRequest *assetRequest = nil;
        if (path != nil) {
            NSString *suffix = [path pathExtension];
            if ([suffix isEqualToString:@"mov"]) {
                assetRequest =  [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:path];
            }else{
                assetRequest =  [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:path];
            }
        }else{
            assetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:weakSelf.images[0]];
        }
        // 2.3 创建一个占位对象
        PHObjectPlaceholder *placeholder = [assetRequest placeholderForCreatedAsset];
        localIdentifier = placeholder.localIdentifier;

        // 2.4 将占位对象添加到相册请求中
        [collectionRequest addAssets:@[placeholder]];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            [self savaSuccess];
        } else {
            
        }
    }];
}

-(void)savaSuccess{
    NSURL *path = nil;
    if (self.paths != nil) {
        path = self.paths[0];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        [fileManager removeItemAtURL:path error:&error];
        if (error != nil) {
            //删除原始文件失败
        }else{
            
        }
        [self.paths removeObjectAtIndex:0];
    }else if(self.images != nil){
        [self.images removeObjectAtIndex:0];
    }
    [self.source addObject:[self latestAsset]];
    NSLog(@"%@", self.source);
    if (self.paths != nil&&[self.paths count] >0) {
        [self prepareSave];
    }else if(self.paths != nil&&[self.paths count] == 0){
        if (self.sComplete) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.sComplete([self.source copy]);
            });
        }
    }
    if (self.images != nil && [self.images count] >0) {
        [self prepareSave];
    }else if(self.images != nil&&[self.images count] == 0){
        if (self.sComplete) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.sComplete([self.source copy]);
            });
        }
    }
}

- (PHAsset *)latestAsset {
    // 获取所有资源的集合，并按资源的创建时间排序
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    PHFetchResult *assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];
    return [assetsFetchResults firstObject];
}

-(PHAssetCollectionChangeRequest *)getCurrentPhotoCollection{
    // 1. 创建搜索集合
    PHFetchResult *result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    
    // 2. 遍历搜索集合并取出对应的相册，返回当前的相册changeRequest
    for (PHAssetCollection *assetCollection in result) {
        if ([assetCollection.localizedTitle containsString:ALbumName]) {
            PHAssetCollectionChangeRequest *collectionRuquest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
            return collectionRuquest;
        }
    }
    
    // 3. 如果不存在，创建一个名字为ALbumName的相册changeRequest
    PHAssetCollectionChangeRequest *collectionRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:ALbumName];
    return collectionRequest;
}





@end
