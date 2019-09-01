//
//  UIImage+WJLibrary.m
//  Expecta
//
//  Created by 王文建 on 2019/9/1.
//

#import "UIImage+WJLibrary.h"
#import "NSBundle+WJLibrary.h"

@implementation UIImage (WJLibrary)

+ (UIImage *)wj_bundleImageNamed:(NSString *)name {
    return [self wj_imageNamed:name inBundle:[NSBundle wj_LibraryBundle]];
}


+ (UIImage *)wj_imageNamed:(NSString *)name inBundle:(NSBundle *)bundle {
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0
    return [UIImage imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
#elif __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_8_0
    return [UIImage imageWithContentsOfFile:[bundle pathForResource:name ofType:@"png"]];
#else
    if ([UIImage respondsToSelector:@selector(imageNamed:inBundle:compatibleWithTraitCollection:)]) {
        return [UIImage imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
    } else {
        return [UIImage imageWithContentsOfFile:[bundle pathForResource:name ofType:@"png"]];
    }
#endif
}
@end
