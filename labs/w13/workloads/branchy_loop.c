#include <stdint.h>
#include <stdio.h>

#ifndef N
#define N 32768
#endif
#ifndef ITERS
#define ITERS 32
#endif

static uint32_t x[N];

int main(void) {
    for (int i = 0; i < N; i++) {
        uint32_t v = (uint32_t)(i * 2654435761u);
        x[i] = v ^ (v >> 13);
    }

    volatile uint64_t acc = 0;
    for (int r = 0; r < ITERS; r++) {
        for (int i = 0; i < N; i++) {
            uint32_t v = x[i];
            if ((v & 7u) == 0u) {
                acc += v * 3u;
            } else if ((v & 3u) == 1u) {
                acc ^= (uint64_t)v << 1;
            } else {
                acc += v >> 2;
            }
        }
    }

    printf("branchy_loop: N=%d ITERS=%d acc=%llu\n", N, ITERS, (unsigned long long)acc);
    return (acc == 0) ? 1 : 0;
}
