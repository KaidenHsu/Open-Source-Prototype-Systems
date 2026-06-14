#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef N
#define N 16384
#endif
#ifndef ITERS
#define ITERS 64
#endif

static uint32_t a[N];

int main(void) {
    for (int i = 0; i < N; i++) {
        a[i] = (uint32_t)((i * 1103515245u + 12345u) & 0xffffu);
    }

    volatile uint64_t sum = 0;
    for (int r = 0; r < ITERS; r++) {
        for (int i = 0; i < N; i++) {
            sum += a[i];
        }
    }

    printf("array_sum: N=%d ITERS=%d sum=%llu\n", N, ITERS, (unsigned long long)sum);
    return (sum == 0) ? 1 : 0;
}
