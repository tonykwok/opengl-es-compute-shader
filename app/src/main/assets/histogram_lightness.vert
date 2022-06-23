uniform sampler2D inTexture;

const float TEXTURE_WIDTH = 1920.0;
const float TEXTURE_HIEGHT = 1080.0;

void main()
{
    // TODO: Farbe auslesen
    vec2 TexCoord = gl_Vertex.xy;
    TexCoord.x = TexCoord.x / TEXTURE_WIDTH;
    TexCoord.y = TexCoord.y / TEXTURE_HIEGHT;
    vec3 color = texture2D(imageTexture, TexCoord.st).rgb;

    // TODO: Grauwert berechnen
    float greyscale = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;

    // TODO: x-Position berechnen. Das Zielpixel ist zwischen (0,0) und (255,0)
    float Xposition = greyscale * 255.0;

    // TODO: Die Position in [0,1] auf das Intervall [-1,1] abbilden.
    vec2 Vertex = vec2(0);
    Vertex.x = (Xposition - 255.0) / 255.0;

    gl_Position = vec4(Vertex.x, -1.0, 0.0, 1.0);
}