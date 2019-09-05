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
    WJCameraConfig *config = [WJCameraConfig config];
    config.Max_time = 10; //Default 15 s
    WJCameraController *wjc =[WJCameraController buildWithConfig:config];
    wjc.delegate = self;
    [self presentViewController:wjc animated:YES completion:nil];
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
