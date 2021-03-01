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
   
    WJCameraController *wjc =[[WJCameraController alloc]initWithTakeMode:ALL delegate:self];
    wjc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:wjc animated:YES completion:nil];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self start:nil];
}

- (void)recodeVideoComplete:(NSURL * _Nullable)videoPath {
    NSLog(@"%@", videoPath);
}

- (void)takePhotoComplete:(UIImage * _Nullable)image {
    NSLog(@"%@", image);
}


@end
