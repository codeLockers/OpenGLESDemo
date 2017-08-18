//
//  OpenGLView.m
//  Demo6
//
//  Created by codeLocker on 2017/8/18.
//  Copyright © 2017年 codeLocker. All rights reserved.
//

#import "OpenGLView.h"
#import <OpenGLES/ES2/gl.h>
#import "CC3GLMatrix.h"

@interface OpenGLView () {
    EAGLContext *_context;
    CAEAGLLayer *_eglLayer;
    GLuint _colorRenderBuffer;
    
    GLuint _depthRenderBuffer;
    
    GLuint _program;
    /** 用于绑定shader中的position参数 */
    GLuint _positionSlot;
    /** 用于绑定shader中的SourceColor参数 */
    GLuint _colorSlot;
    
    GLuint _projectionUniform;
    
    GLuint _modelViewUniform;
    float _currentRotation;
}
@end

typedef struct {
    float Position[3];
    float Color[4];
}Vertex;

const Vertex Vertexs[] = {
    {{1, -1, 0},  {1, 0, 0, 1}},
    {{1, 1, 0},   {1, 0, 0, 1}},
    {{-1, 1, 0},  {0, 1, 1, 1}},
    {{-1, -1, 0}, {0, 1, 0, 1}},
    
    {{1, -1, -1},  {1, 0, 0, 1}},
    {{1, 1, -1},   {1, 0, 0, 1}},
    {{-1, 1, -1},  {0, 1, 1, 1}},
    {{-1, -1, -1}, {0, 1, 0, 1}}
};

const GLubyte Indices[] = {
    // Front
    0, 1, 2,
    2, 3, 0,
    // Back
    4, 6, 5,
    4, 7, 6,
    // Left
    2, 7, 3,
    7, 6, 2,
    // Right
    0, 4, 1,
    4, 1, 5,
    // Top
    6, 2, 1,
    1, 6, 5,
    // Bottom
    0, 3, 7,
    0, 7, 4
};

@implementation OpenGLView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupLayer];
        [self setupContext];
        [self setupDepthBuffer];
        [self setupRenderBuffer];
        [self setupFrameBuffer];
        
        _program = [OpenGLView compileVertexShader:@"ShaderVertex" fragmentShader:@"ShaderFragment"];
        glUseProgram(_program);
        
        _positionSlot = glGetAttribLocation(_program, "Position");
        _colorSlot = glGetAttribLocation(_program, "SourceColor");
        glEnableVertexAttribArray(_positionSlot);
        glEnableVertexAttribArray(_colorSlot);
        
        
        _projectionUniform = glGetUniformLocation(_program, "Projection");
        _modelViewUniform = glGetUniformLocation(_program, "Modelview");
        
        [self setupVBOs];
        [self setupDisplayLink];
    }
    return self;
}

- (void)setupDisplayLink {
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

// Modify render method to take a parameter
- (void)render:(CADisplayLink*)displayLink {
    glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);

    CC3GLMatrix *projection = [CC3GLMatrix matrix];
    float h = 4.0f * self.frame.size.height / self.frame.size.width;
    [projection populateFromFrustumLeft:-2 andRight:2 andBottom:-h/2 andTop:h/2 andNear:4 andFar:10];
    glUniformMatrix4fv(_projectionUniform, 1, 0, projection.glMatrix);
    

    CC3GLMatrix *modelView = [CC3GLMatrix matrix];
    [modelView populateFromTranslation:CC3VectorMake(sin(CACurrentMediaTime()), 0, -7)];

    _currentRotation += displayLink.duration * 90;
    [modelView rotateBy:CC3VectorMake(_currentRotation, _currentRotation, 0)];
    
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelView.glMatrix);
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glEnableVertexAttribArray(_positionSlot);
    
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)(sizeof(float) * 3));
    glEnableVertexAttribArray(_colorSlot);
    glDrawElements(GL_TRIANGLE_STRIP, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    
}



- (void)setupLayer {
    _eglLayer = (CAEAGLLayer *)self.layer;
    _eglLayer.opaque = YES;
}

- (void)setupContext {
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_context) {
        exit(1);
    }
    if(![EAGLContext setCurrentContext:_context]) {
        exit(1);
    }
}

- (void)setupDepthBuffer {
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.width, self.frame.size.height);
}

- (void)setupRenderBuffer {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eglLayer];
}

- (void)setupFrameBuffer {
    GLuint frameBuffer;
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
}

- (void)setupVBOs {
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertexs), Vertexs, GL_STATIC_DRAW);
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
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
    GLint vertex = [OpenGLView compileShader:vertexShader type:GL_VERTEX_SHADER];
    GLint fragment = [OpenGLView compileShader:fragmentShader type:GL_FRAGMENT_SHADER];
    
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
