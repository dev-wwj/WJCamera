//
//  NSBundle+WJ.m
//  Expecta
//
//  Created by 王文建 on 2019/9/1.
//

#import "NSBundle+WJ.h"

@implementation NSBundle (WJLibrary)

+ (NSBundle *)wj_LibraryBundle {
    NSBundle *bundle = [NSBundle bundleForClass:NSClassFromString(@"WJCameraController")];
    if (![bundle.bundleIdentifier isEqualToString:[NSBundle mainBundle].bundleIdentifier]) {
        return [NSBundle bundleWithURL:[bundle URLForResource:@"images" withExtension:@"bundle"]];
    }else {
        return [NSBundle mainBundle];
    }
}

@end
