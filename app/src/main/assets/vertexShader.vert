attribute vec2 aPosition; // 图形顶点
attribute vec2 aTexCoord; // 纹理与图形顶点的映射关系

uniform mat4 uTextureMatrix;
varying vec2 texCoord;

void main()
{
    texCoord = (uTextureMatrix * vec4(aTexCoord, 0.0, 1.0)).xy;
    gl_Position = vec4(aPosition.x, aPosition.y, 0.0, 1.0);
}

//attribute vec4 aPosition;
//uniform mat4 uTextureMatrix;
//attribute vec4 aTextureCoordinate;
//varying vec2 vTextureCoord;
//void main()
//{
//    vTextureCoord = (uTextureMatrix * aTextureCoordinate).xy;
//    gl_Position = aPosition;
//}