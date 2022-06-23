attribute vec2 aPosition; // 图形顶点
attribute vec2 aTexCoord; // 纹理与图形顶点的映射关系
varying vec2 texCoord;

void main()
{
    texCoord = aTexCoord;
    gl_Position = vec4 ( aPosition.x, aPosition.y, 0.0, 1.0 );
}