#include <metal_stdlib>
using namespace metal;

uint deinterleave(uint x);
uint interleave(uint x);
uint prefixScan(uint x);
uint descan(uint x);


uint deinterleave(uint x)
{
    x = x & 0x55555555;
    x = (x | (x >> 1)) & 0x33333333;
    x = (x | (x >> 2)) & 0x0F0F0F0F;
    x = (x | (x >> 4)) & 0x00FF00FF;
    x = (x | (x >> 8)) & 0x0000FFFF;
    return x;
}

uint interleave(uint x)
{
    x = (x | (x << 8)) & 0x00FF00FF;
    x = (x | (x << 4)) & 0x0F0F0F0F;
    x = (x | (x << 2)) & 0x33333333;
    x = (x | (x << 1)) & 0x55555555;
    return x;
}

uint prefixScan(uint x)
{
    x = (x >> 8) ^ x;
    x = (x >> 4) ^ x;
    x = (x >> 2) ^ x;
    x = (x >> 1) ^ x;
    return x;
}

uint descan(uint x)
{
    return x ^ (x >> 1);
}

kernel void hilbertIndexToXY(const device uint &n [[ buffer(0) ]],
                             device uint *xBuffer [[ buffer(1) ]],
                             device uint *yBuffer [[ buffer(2) ]],
                             uint index [[ thread_position_in_grid ]]
                             ) {
    
    uint i = index;
    
    i = i << (32 - 2 * n);
    
    uint i0 = deinterleave(i);
    uint i1 = deinterleave(i >> 1);
    
    uint t0 = (i0 | i1) ^ 0xFFFF;
    uint t1 = i0 & i1;
    
    uint prefixT0 = prefixScan(t0);
    uint prefixT1 = prefixScan(t1);
    
    uint a = (((i0 ^ 0xFFFF) & prefixT1) | (i0 & prefixT0));
    
    xBuffer[index] = (a ^ i1) >> (16 - n);
    yBuffer[index] = (a ^ i0 ^ i1) >> (16 - n);
}

kernel void hilbertXYToIndex(const device uint &n [[ buffer(0) ]],
                             const device uint *xBuffer [[ buffer(1) ]],
                             const device uint *yBuffer [[ buffer(2) ]],
                             device uint *out [[ buffer(3) ]],
                             uint index [[ thread_position_in_grid ]]
                             ) {
    
    uint x = xBuffer[index] << (16 - n);
    uint y = yBuffer[index] << (16 - n);
    
    uint A, B, C, D;
    
    // Initial prefix scan round, prime with x and y
    {
        uint a = x ^ y;
        uint b = 0xFFFF ^ a;
        uint c = 0xFFFF ^ (x | y);
        uint d = x & (y ^ 0xFFFF);
        
        A = a | (b >> 1);
        B = (a >> 1) ^ a;
        
        C = ((c >> 1) ^ (b & (d >> 1))) ^ c;
        D = ((a & (c >> 1)) ^ (d >> 1)) ^ d;
    }
    
    {
        uint a = A;
        uint b = B;
        uint c = C;
        uint d = D;
        
        A = ((a & (a >> 2)) ^ (b & (b >> 2)));
        B = ((a & (b >> 2)) ^ (b & ((a ^ b) >> 2)));
        
        C ^= ((a & (c >> 2)) ^ (b & (d >> 2)));
        D ^= ((b & (c >> 2)) ^ ((a ^ b) & (d >> 2)));
    }
    
    {
        uint a = A;
        uint b = B;
        uint c = C;
        uint d = D;
        
        A = ((a & (a >> 4)) ^ (b & (b >> 4)));
        B = ((a & (b >> 4)) ^ (b & ((a ^ b) >> 4)));
        
        C ^= ((a & (c >> 4)) ^ (b & (d >> 4)));
        D ^= ((b & (c >> 4)) ^ ((a ^ b) & (d >> 4)));
    }
    
    // Final round and projection
    {
        uint a = A;
        uint b = B;
        uint c = C;
        uint d = D;
        
        C ^= ((a & (c >> 8)) ^ (b & (d >> 8)));
        D ^= ((b & (c >> 8)) ^ ((a ^ b) & (d >> 8)));
    }
    
    // Undo transformation prefix scan
    uint a = C ^ (C >> 1);
    uint b = D ^ (D >> 1);
    
    // Recover index bits
    uint i0 = x ^ y;
    uint i1 = b | (0xFFFF ^ (i0 | a));
    
    uint result = ((interleave(i1) << 1) | interleave(i0)) >> (32 - 2 * n);
    
    out[index] = result;
}
