#version 310 es

layout(rgba8, binding = 1) uniform readonly highp image2D inTexture;
layout(rgba8, binding = 2) uniform writeonly highp image2D outTexture;

layout(location = 3) uniform ivec2 alignmentMin;
layout(location = 4) uniform ivec2 alignmentMax;

layout(std430, binding = 5) buffer ssbOutput {
    int gHistogram[];
};

layout(std430, binding = 6) buffer ssbOutput {
    int gPerTileHistogram[];
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

    ivec2 dim = imageSize(inTexture).xy;

    // Which pixel within a tile
    uint local_index_flattened = gl_LocalInvocationID.x + gl_LocalInvocationID.y * gl_WorkGroupSize.x;
    // Which tile from the screen
    uint tile_index_flattened = gl_WorkGroupID.x + gl_WorkGroupID.y * gl_NumWorkGroups.x;
    // Initialise the contents of the group shared memory.
    // Only one thread does it to avoid bank conflict overhead
    if (local_index_flattened == 0u) {
        for (int index = 0; index < 256; ++index) {
            sHistogram[index] = 0;
        }
    }
    barrier();

    // For each thread, update the histogram

    // It is possible that we emit more threads than we have pixels.
    // This is caused due to rounding up an image to a multiple of the tile size
    if (gl_GlobalInvocationID.x < dim.x && gl_GlobalInvocationID.y < dim.y) {
        // We just use sample 0 for efficiency reasons.
        // It is unlikely that omitting the extra samples will make a significant difference to the histogram
        vec4 texColor = imageLoad(inTexture, ivec2(gl_GlobalInvocationID.xy));
        float greyScale = luminance(texColor.rgb);
        int bin = int(greyScale * 255.0);
        atomicAdd(sHistogram[bin], 1);
    }
    barrier();

    // Thread 0 outputs this thread group's histogram to the buffer
    if (local_index_flattened == 0u) {
        // This could write uint4s to the UAV as an optimisation
        uint outputHistogramIndex = 256u * tile_index_flattened;
        for(int index = 0; index < 256; ++index) {
            uint outputIndex = index + outputHistogramIndex;
            gPerTileHistogram[outputIndex] = sHistogram[index];
        }
    }

    // Ensure that memory accesses to shared variables complete.
    memoryBarrierBuffer();

    // Each thread has the job of adding in the contents of the per-tile histogram to the overall histogram stored in GSM
    // This is an atomic operation, because many, many threads are trying to hit that memory simultaneously
    if (local_index_flattened == 0u) {
        for (int bin = 0; bin < 256; ++bin) {
            atomicAdd(gHistogram[bin], gPerTileHistogram[tile_index_flattened * 256 + bin]);
        }
    }
}
