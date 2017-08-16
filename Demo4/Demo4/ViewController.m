//
//  ViewController.m
//  Demo4
//
//  Created by codeLocker on 2017/8/16.
//  Copyright © 2017年 codeLocker. All rights reserved.
//

#import "ViewController.h"
#import <GLKit/GLKit.h>

@interface ViewController () {
    GLuint _renderBuffer;//渲染缓冲区
    GLuint _frameBuffer;//帧缓冲区
    
    GLuint _glProgram;
    GLuint _positionSlot;// 用于绑定shader中的Position参数
}
/** OpenGL context,管理使用opengl es进行绘制的状态,命令及资源 */
@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, strong) CAEAGLLayer *layer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //创建context
    //setup context, 渲染上下文，管理所有绘制的状态，命令及资源信息。
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    //设置为当前上下文。
    [EAGLContext setCurrentContext:self.context];
    
    //创建layer
    //setup layer, 必须要是CAEAGLLayer才行，才能在其上描绘OpenGL内容
    //如果在viewController中，使用[self.view.layer addSublayer:eaglLayer];
    //如果在view中，可以直接重写UIView的layerClass类方法即可return [CAEAGLLayer class]。
    self.layer = [CAEAGLLayer layer];
    self.layer.frame = self.view.frame;
    //CALayer默认是透明的
    self.layer.opaque = YES;
    // 描绘属性：这里不维持渲染内容
    // kEAGLDrawablePropertyRetainedBacking:若为YES，则使用glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)计算得到的最终结果颜色的透明度会考虑目标颜色的透明度值。
    // 若为NO，则不考虑目标颜色的透明度值，将其当做1来处理。
    // 使用场景：目标颜色为非透明，源颜色有透明度，若设为YES，则使用glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)得到的结果颜色会有一定的透明度（与实际不符）。若未NO则不会（符合实际）。
    self.layer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat, nil];
    [self.view.layer addSublayer:self.layer];
    
    //清空buffer
    if (_renderBuffer) {
        glDeleteRenderbuffers(1, &_renderBuffer);
        _renderBuffer = 0;
    }
    if (_frameBuffer) {
        glDeleteRenderbuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }
    
    //配置buffer
    //先要renderbuffer，然后framebuffer，顺序不能互换。
    // OpenGlES共有三种：colorBuffer，depthBuffer，stencilBuffer。
    // 生成一个renderBuffer，id是_colorRenderBuffer
    glGenRenderbuffers(1, &_renderBuffer);
    // 设置为当前renderBuffer
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    //为color renderbuffer 分配存储空间
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.layer];
    
    // FBO用于管理colorRenderBuffer，离屏渲染
    glGenFramebuffers(1, &_frameBuffer);
    //设置为当前framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    
    // 设置清屏颜色
    glClearColor(0.0f, 0.0f, 1.0f, 1.0f);
    // 用来指定要用清屏颜色来清除由mask指定的buffer，此处是color buffer
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    //编译shader
    _glProgram = [ViewController compileVertexShader:@"ShaderVertex" fragmentShader:@"ShaderFragment"];
    glUseProgram(_glProgram);
    // 获取指向vertex shader传入变量的指针, 然后就通过该指针来使用
    // 即将_positionSlot 与 shader中的Position参数绑定起来
    glGetAttribLocation(_glProgram, "Position");
    
    [self render];
    
    // 将指定renderBuffer渲染在屏幕上
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)render {
//    [self renderVertices];
//    [self renderUsingIndex];
//    [self renderUsingVBO];
    [self renderUsingIndexVBO];
}

- (void)renderVertices {
    const GLfloat vertices[] = {
        0.0f, 0.5f, 0.0f,
        -0.5f,-0.5f,0.0f,
        0.5f,-0.5f,0.0f
    };
    // Load the vertex data，(不使用VBO)则直接从CPU中传递顶点数据到GPU中进行渲染
    // 给_positionSlot传递vertices数据
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    glEnableVertexAttribArray(_positionSlot);
    // Draw triangle
    glDrawArrays(GL_TRIANGLES, 0, 3);
}

- (void)renderUsingIndex {
    const GLfloat vertices[] = {
        0.0f, 0.5f, 0.0f,
        -0.5f,-0.5f,0.0f,
        0.5f,-0.5f,0.0f
    };
    const GLubyte indices[] = {
        0,1,2
    };
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    glEnableVertexAttribArray(_positionSlot);
    
    glDrawElements(GL_TRIANGLES, sizeof(indices)/sizeof(indices[0]), GL_UNSIGNED_BYTE, indices);
}

- (void)renderUsingVBO {
    const GLfloat vertices[] = {
        0.0f, 0.5f, 0.0f,
        -0.5f,-0.5f,0.0f,
        0.5f,-0.5f,0.0f
    };
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    // 绑定vertexBuffer到GL_ARRAY_BUFFER目标
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    //为VBO申请空间，初始化并传递数据
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    //使用VBO时，最后一个参数0为要获取参数在GL_ARRAY_BUFFER中的偏移量
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 0, 0);
    glEnableVertexAttribArray(_positionSlot);
    
    glDrawArrays(GL_TRIANGLES, 0, 3);
}

- (void)renderUsingIndexVBO {
    const GLfloat vertices[] = {
        0.0f, 0.5f, 0.0f,
        -0.5f,-0.5f,0.0f,
        0.5f,-0.5f,0.0f
    };
    const GLubyte indices[] = {
        0,1,2
    };
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    //绑定vertexBuffer到GL_ARRAY_BIFFER目标
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    //为VBO申请空间，初始化并传递数据
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    //使用VBO时，最后一个参数0为要获取参数在GL_ARRAY_BUFFER中的偏移量
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 0, 0);
    glEnableVertexAttribArray(_positionSlot);
    
    glDrawElements(GL_TRIANGLES, sizeof(indices)/sizeof(indices[0]), GL_UNSIGNED_BYTE, 0);
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
