#version 310 es

layout(rgba8, binding = 1) uniform readonly highp image2D inTexture;
layout(rgba8, binding = 2) uniform writeonly highp image2D outTexture;

layout(location = 3) uniform ivec2 alignmentMin;
layout(location = 4) uniform ivec2 alignmentMax;

layout(std430, binding = 5) buffer ssbOutput {
    int gHistogram[256];
};

float luminance(in vec3 color) {
    return dot(color, vec3(0.299, 0.587, 0.114));
}

shared int sHistogram[256];
layout (local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

void main()
{
    ivec2 ipos = ivec2(gl_GlobalInvocationID.xy);
    uint gWidth = gl_WorkGroupSize.x * gl_NumWorkGroups.x;
    uint gHeight = gl_WorkGroupSize.y * gl_NumWorkGroups.y;
    int idx = int(ipos.y) * int(gWidth) + int(ipos.x);
    if (idx < 256) {
        gHistogram[idx] = 0;
    }
    // Ensure that memory accesses to shared variables complete.
    memoryBarrierBuffer();

    // Initialize the bin for this thread to 0
    sHistogram[gl_LocalInvocationIndex] = 0;
    barrier();

    ivec2 dim = imageSize(inTexture).xy;
    // Ignore threads that map to areas beyond the bounds of our input image
    if (ipos.x < dim.x && ipos.y < dim.y) {
        vec4 texColor = imageLoad(inTexture, ipos);
        float lum = luminance(texColor.rgb);
        imageStore(outTexture, ipos, vec4(lum));
        int bin = int(lum * 255.0);
        // We use an atomic add to ensure we don't write to the same bin in our
        // histogram from two different threads at the same time.
        atomicAdd(sHistogram[bin], 1);
    }

    // Wait for all threads in the work group to reach this point before adding our
    // local histogram to the global one
    barrier();

    // Technically there's no chance that two threads write to the same bin here,
    // but different work groups might! So we still need the atomic add.
    atomicAdd(gHistogram[gl_LocalInvocationIndex], sHistogram[gl_LocalInvocationIndex]);
}
