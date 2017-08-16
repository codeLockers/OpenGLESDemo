//
//  ViewController.m
//  Demo1
//
//  Created by codeLocker on 2017/7/21.
//  Copyright © 2017年 codeLocker. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
/** 上下文 */
@property (nonatomic, strong) EAGLContext * context;
/** 显示相关 */
@property (nonatomic, strong) GLKBaseEffect *effect;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //新建OpenGLES 上下文
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    //颜色缓冲区格式
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    //设置当前上下文
    [EAGLContext setCurrentContext:self.context];
    
    //顶点数据，前三个是顶点坐标，后面两个是纹理坐标
    //在OpenGL ES只能绘制三角形,不能绘制多边形,但是在OpenGL中确实可以直接绘制多边形
    GLfloat squareVertexData[] =
    {
        0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
        0.5, 0.5, -0.0f,    1.0f, 1.0f, //右上
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
        
        0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
        -0.5, -0.5, 0.0f,   0.0f, 0.0f, //左下
    };
    //顶点数据缓存到GPU
    GLuint buffer;
    //先系统申请1个缓存区,标识符为buffer
    glGenBuffers(1, &buffer);
    //buffer绑定顶点数据  GL_ARRAY_BUFFER:顶点数据
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    //把CPU中的内存中的数组复制到GPU的内存中 GL_STATIC_DRAW:只能被修改一次但可以无限次读取
    glBufferData(GL_ARRAY_BUFFER, sizeof(squareVertexData), squareVertexData, GL_STATIC_DRAW);
    //顶点数据
    //激活顶点数据
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    // 往对应的顶点属性中添加数据
    //indx为顶点属性类型
    //size为每个数据中的数据长度
    //type为元素数据类型
    //normalized填充时需不需要单位化
    //stride需要填写的是在数据数组中每行的跨度
    //ptr指针是说的是每一个数据的起始位置将从内存数据块的什么地方开始
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);
    //纹理数据
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat*)NULL + 3);
    
    //纹理贴图
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"test1" ofType:@"jpeg"];
    //GLKTextureLoaderOriginBottomLeft 纹理坐标系是相反的
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:@(1), GLKTextureLoaderOriginBottomLeft, nil];
    //纹理
    GLKTextureInfo* textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];
    //着色器
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.texture2d0.name = textureInfo.name;
}

//渲染
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    //渲染前的“清除”操作,指定在清除屏幕之后填充什么样的颜色
    glClearColor(1, 0, 0, 1.0f);
    //指定需要清除的缓冲.mask指定缓冲的类型
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    //启动着色器
    [self.effect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 6);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
