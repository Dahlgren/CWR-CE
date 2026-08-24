// Accumulated each frame, read+reset by benchmark code
#pragma once

#include <cstdint>

#if defined(_WIN32) && !(defined(_M_ARM64) || defined(__aarch64__))
#include <intrin.h>
#pragma intrinsic(__rdtsc)
#endif


namespace Poseidon
{
struct TerrainProfile {
    int segmentsDrawn;
    int segmentsCacheHit;
    int segmentsCacheMiss;
    int drawMeshCalls;
    int drawMeshClipped;
    int cacheSearchSteps;
    double drawGroundCycles;
    double generateSegCycles;

    void Reset() { *this = {}; }

    static int64_t Now() {
#if defined(_WIN32) && (defined(_M_ARM64) || defined(__aarch64__))
        return static_cast<int64_t>(__builtin_arm_rsr64("CNTVCT_EL0"));
#elif defined(_WIN32)
        return static_cast<int64_t>(__rdtsc());
#elif defined(__x86_64__) || defined(__i386__)
        unsigned int lo, hi;
        __asm__ __volatile__("rdtsc" : "=a"(lo), "=d"(hi));
        return (static_cast<int64_t>(hi) << 32) | lo;
#elif defined(__aarch64__)
        int64_t val;
        __asm__ __volatile__("mrs %0, cntvct_el0" : "=r"(val));
        return val;
#else
        return 0;
#endif
    }
};

extern TerrainProfile GTerrainProfile;

}  // namespace Poseidon
