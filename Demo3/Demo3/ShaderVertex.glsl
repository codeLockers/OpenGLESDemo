//http://blog.csdn.net/icetime17/article/details/50436927
attribute vec4 Position;
attribute vec4 SourceColor;

varying vec4 DestinationColor;

void main(void) {
    
    DestinationColor = SourceColor;
    gl_Position = Position;
}
