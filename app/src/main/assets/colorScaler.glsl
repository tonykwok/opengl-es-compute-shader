#version 310 es
#extension GL_OES_EGL_image_external_essl3 : enable

layout(rgba8, binding = 1) uniform readonly highp image2D inTexture;

layout(rgba8, binding = 2) uniform writeonly highp image2D outTexture;

layout(location = 3) uniform ivec2 alignmentMin;

layout(location = 4) uniform ivec2 alignmentMax;

layout(location = 5) uniform int colorScale;

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

void main()
{
    ivec2 storePos = ivec2(gl_GlobalInvocationID.xy);

    vec4 texColor = imageLoad(inTexture, storePos).rgba;

    if (storePos.x > alignmentMin.x && storePos.x < alignmentMax.x) {
        if (storePos.y > alignmentMin.y && storePos.y < alignmentMax.y) {

            if (colorScale == 0) {

                float newPixel = 0.299 * texColor.r + 0.587 * texColor.g + 0.114 * texColor.b;

                imageStore(outTexture, storePos, vec4(newPixel, newPixel, newPixel, texColor.a));
            } else {
                imageStore(outTexture, storePos, vec4(1.5 * texColor.r, 0.1 * texColor.g, 0.3 * texColor.b, texColor.a));
            }
        } else {

            if (colorScale == 0) {
                imageStore(outTexture, storePos, texColor);
            } else {
                imageStore(outTexture, storePos, vec4(0.3 * texColor.r, 1.5 * texColor.g, 0.3 * texColor.b, texColor.a));
            }
        }
    } else {
        if (colorScale == 0) {
            imageStore(outTexture, storePos, texColor);
        } else {
            imageStore(outTexture, storePos, vec4(0.3 * texColor.r, 0.1 * texColor.g, 1.5 * texColor.b, texColor.a));
        }
    }
}