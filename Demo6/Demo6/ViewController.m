//
//  ViewController.m
//  Demo6
//
//  Created by codeLocker on 2017/8/18.
//  Copyright © 2017年 codeLocker. All rights reserved.
//

#import "ViewController.h"
#import "OpenGLView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    OpenGLView *glView = [[OpenGLView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.view addSubview:glView];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
