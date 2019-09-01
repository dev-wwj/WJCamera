//
//  NSBundle+WJLibrary.m
//  Expecta
//
//  Created by 王文建 on 2019/9/1.
//

#import "NSBundle+WJLibrary.h"
#import "WJCameraController.h"

@implementation NSBundle (WJLibrary)

+ (NSBundle *)wj_LibraryBundle {
    return [self bundleWithURL:[self wj_LibraryBundleURL]];
}


+ (NSURL *)wj_LibraryBundleURL {
    NSBundle *bundle = [NSBundle bundleForClass:[WJCameraController class]];
    return [bundle URLForResource:@"WJCamera" withExtension:@"bundle"];
}
@end
