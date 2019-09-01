//
//  WJViewController.m
//  WJCamera
//
//  Created by scorpion on 08/29/2019.
//  Copyright (c) 2019 scorpion. All rights reserved.
//

#import "WJViewController.h"
#import "WJCameraController.h"

@interface WJViewController ()<CameraDelegate>

@end

@implementation WJViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)start:(id)sender {
    WJCameraController *wjc =[[WJCameraController alloc] init];
    [self presentViewController:wjc animated:YES completion:nil];
    wjc.delegate = self;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
  
    
}

-(void)completeWithAsset:(PHAsset*)asset image:(UIImage *)image videoPath:(NSURL*)videoPath{
    NSLog(@"asset---%@",asset);
    NSLog(@"image---%@",image);
    NSLog(@"videoPath---%@",videoPath);
}


@end
