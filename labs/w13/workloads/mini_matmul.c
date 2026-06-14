#include <stdint.h>
#include <stdio.h>

#ifndef N
#define N 48
#endif
#ifndef ITERS
#define ITERS 6
#endif

static int32_t A[N][N];
static int32_t B[N][N];
static int32_t C[N][N];

int main(void) {
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            A[i][j] = (i + j) & 15;
            B[i][j] = (i * 3 - j) & 15;
            C[i][j] = 0;
        }
    }

    for (int r = 0; r < ITERS; r++) {
        for (int i = 0; i < N; i++) {
            for (int k = 0; k < N; k++) {
                int32_t aik = A[i][k];
                for (int j = 0; j < N; j++) {
                    C[i][j] += aik * B[k][j];
                }
            }
        }
    }

    volatile int64_t checksum = 0;
    for (int i = 0; i < N; i++) {
        checksum += C[i][i];
    }
    printf("mini_matmul: N=%d ITERS=%d checksum=%lld\n", N, ITERS, (long long)checksum);
    return (checksum == 0) ? 1 : 0;
}
