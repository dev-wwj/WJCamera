//
//  NSBundle+WJLibrary.h
//  Expecta
//
//  Created by 王文建 on 2019/9/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (WJLibrary)

+ (NSBundle *)wj_LibraryBundle;
+ (NSURL *)wj_LibraryBundleURL;
@end

NS_ASSUME_NONNULL_END
