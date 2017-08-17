//
//  ViewController.m
//  Demo5
//
//  Created by codeLocker on 2017/8/17.
//  Copyright © 2017年 codeLocker. All rights reserved.
//

#import "ViewController.h"
#import <OpenGLES/ES2/gl.h>
@interface ViewController () {
    GLuint _renderBuffer;//渲染缓冲区
    GLuint _frameBuffer;//帧缓冲区
    
    GLuint _glProgram;
}
@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, strong) CAEAGLLayer *layer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //set context
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    //设置为当前上下文
    [EAGLContext setCurrentContext:self.context];
    
    //set layer
    self.layer = [CAEAGLLayer layer];
    self.layer.opaque = YES;
    self.layer.frame = self.view.frame;
    self.layer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat, nil];
    [self.view.layer addSublayer:self.layer];
    
    //清除之前的缓存
    if (_renderBuffer) {
        glDeleteRenderbuffers(1, &_renderBuffer);
        _renderBuffer = 0;
    }
    if (_frameBuffer) {
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }
    
    //渲染缓冲区
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    //分配空间
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.layer];
    
    //帧缓冲区
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    // 将 renderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    
    glClearColor(0, 1.0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
//    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(0, 0, self.view.frame.size.width * 1, self.view.frame.size.height * 1);
    
    //编译shader
    _glProgram = [ViewController compileVertexShader:@"ShaderVertex" fragmentShader:@"ShaderFragment"];
    glUseProgram(_glProgram);
    
    [self render];
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)render {

    //前三个是顶点坐标， 后面两个是纹理坐标
    GLfloat attrArr[] =
    {
        0.5f, -0.5f, -1.0f,     1.0f, 1.0f, //右下
        -0.5f, 0.5f, -1.0f,     0.0f, 0.0f, //左上
        -0.5f, -0.5f, -1.0f,    0.0f, 1.0f, //左下
        
        0.5f, 0.5f, -1.0f,      1.0f, 0.0f, //右上
        -0.5f, 0.5f, -1.0f,     0.0f, 0.0f, //左上
        0.5f, -0.5f, -1.0f,     1.0f, 1.0f, //右下
    };
    
    GLuint attrbuffer;
    glGenBuffers(1, &attrbuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attrbuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    GLuint position = glGetAttribLocation(_glProgram, "position");
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    glEnableVertexAttribArray(position);
    
    GLuint textCoor = glGetAttribLocation(_glProgram, "textCoordinate");
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (float *)NULL + 3);
    glEnableVertexAttribArray(textCoor);
    
    //加载纹理
    CGImageRef spriteImage = [UIImage imageNamed:@"a"].CGImage;
    //读取图片大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte *spriteData = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    //在CGContextRef上绘图
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    CGContextRelease(spriteContext);
    
    //绑定纹理到默认的纹理ID（这里只有一张图片，故而相当于默认于片元着色器里面的colorMap，如果有多张图不可以这么做）
    glBindTexture(GL_TEXTURE_2D, 0);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (float)width, (float)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    glBindTexture(GL_TEXTURE_2D, 0);
    free(spriteData);
    
    
    GLuint rotate = glGetUniformLocation(_glProgram, "rotateMatrix");

    float radians = 10 * 3.14159f / 180.0f;
    float s = sin(radians);
    float c = cos(radians);

    //z轴旋转矩阵
    GLfloat zRotation[16] = { //
        c, -s, 0, 0.2, //
        s, c, 0, 0,//
        0, 0, 1.0, 0,//
        0.0, 0, 0, 1.0//
    };

    //设置旋转矩阵
    glUniformMatrix4fv(rotate, 1, GL_FALSE, (GLfloat *)&zRotation[0]);
    
    glDrawArrays(GL_TRIANGLES, 0, 6);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 编译着色器
+ (GLuint)compileShader:(NSString *)shaderName type:(GLenum)type {
    //查找shader文件
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"shader error");
        return -1;
    }
    
    //创建一个代表shader的OpenGL对象，指定vertex或fragment shader
    GLuint shaderHandle = glCreateShader(type);
    //获取shader的source
    const char* shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    //编译shader
    glCompileShader(shaderHandle);
    //查询shader对象信息
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        //编译失败
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@",messageString);
        return -1;
    }
    return shaderHandle;
}

+ (GLuint)compileVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader {
    //vertex 和 fragment shader都需要编译
    GLint vertex = [ViewController compileShader:vertexShader type:GL_VERTEX_SHADER];
    GLint fragment = [ViewController compileShader:fragmentShader type:GL_FRAGMENT_SHADER];
    
    //连接vertex和fragment shader一个完整的program
    GLint glProgram = glCreateProgram();
    glAttachShader(glProgram, vertex);
    glAttachShader(glProgram, fragment);
    glLinkProgram(glProgram);
    
    //检测link结果
    GLint linkSuccess;
    glGetProgramiv(glProgram, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        //连接失败
        GLchar messages[256];
        glGetProgramInfoLog(glProgram, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        return -1;
    }
    return glProgram;
}
@end
