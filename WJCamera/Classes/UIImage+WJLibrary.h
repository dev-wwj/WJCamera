//
//  UIImage+WJLibrary.h
//  Expecta
//
//  Created by 王文建 on 2019/9/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (WJLibrary)

+ (UIImage *)wj_bundleImageNamed:(NSString *)name ;

+ (UIImage *)wj_imageNamed:(NSString *)name inBundle:(NSBundle *)bundle ;

@end

NS_ASSUME_NONNULL_END
