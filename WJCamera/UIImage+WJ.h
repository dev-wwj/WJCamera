//
//  UIImage+WJ.h
//  Expecta
//
//  Created by 王文建 on 2019/9/1.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (WJLibrary)

+ (UIImage *)wj_bundleImageNamed:(NSString *)name ;

+ (UIImage *)wj_imageNamed:(NSString *)name inBundle:(NSBundle *)bundle ;

//CMSampleBufferRef=>UIImage
+ (UIImage *)imageWithSampleBuffer:(CMSampleBufferRef)sampleBuffer;
@end

NS_ASSUME_NONNULL_END
