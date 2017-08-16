//
//  ViewController.m
//  Demo2
//
//  Created by codeLocker on 2017/7/21.
//  Copyright © 2017年 codeLocker. All rights reserved.
//

#import "ViewController.h"
#import <GLKit/GLKit.h>
@interface ViewController () {
    /** 渲染缓冲区 */
    GLuint _renderBuffer;
    /** 帧缓冲区 */
    GLuint _frameBuffer;
}
@property (nonatomic, strong) EAGLContext *context;
/** 必须要是CAEAGLLayer才行，才能在其上描绘OpenGL内容 */
@property (nonatomic, strong) CAEAGLLayer *eaglLayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //设置context
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
    //初始化Layer
    self.eaglLayer = [[CAEAGLLayer alloc] init];
    self.eaglLayer.frame = [UIScreen mainScreen].bounds;
    self.eaglLayer.opaque = YES;
    //设置layer的绘制属性
    // 描绘属性：这里不维持渲染内容
    // kEAGLDrawablePropertyRetainedBacking:若为YES，则使用glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)计算得到的最终结果颜色的透明度会考虑目标颜色的透明度值。
    // 若为NO，则不考虑目标颜色的透明度值，将其当做1来处理。
    // 使用场景：目标颜色为非透明，源颜色有透明度，若设为YES，则使用glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)得到的结果颜色会有一定的透明度（与实际不符）。若未NO则不会（符合实际）。

    self.eaglLayer.drawableProperties = @{
                                          kEAGLDrawablePropertyRetainedBacking:@(NO),
                                          kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8
                                          };
    [self.view.layer addSublayer:self.eaglLayer];
    
    //清除原来的缓冲区
    if (_renderBuffer) {
        glDeleteBuffers(1, &_renderBuffer);
        _renderBuffer = 0;
    }
    if (_frameBuffer) {
        glDeleteBuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }
    
    //设置缓冲区
    //先要renderbuffer，然后framebuffer，顺序不能互换
    // OpenGlES共有三种：colorBuffer，depthBuffer，stencilBuffer。
    // 生成一个renderBuffer，id是_renderBuffer
    glGenRenderbuffers(1, &_renderBuffer);
    // 设置为当前renderBuffer
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    //为color renderbuffer 分配存储空间
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eaglLayer];
    
    // FBO用于管理_renderBuffer，离屏渲染
    glGenFramebuffers(1, &_frameBuffer);
    //设置为当前framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    
    // 设置清屏颜色
    glClearColor(0.0f, 0.0f, 1.0f, 1.0f);
    // 用来指定要用清屏颜色来清除由mask指定的buffer，此处是color buffer
    glClear(GL_COLOR_BUFFER_BIT);
    
    // 将指定renderBuffer渲染在屏幕上
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
