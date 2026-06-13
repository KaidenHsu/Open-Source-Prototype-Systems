#include "input_image.h"
#include "kernel.h"
#include "checksum.h"

volatile int sink;
int out[H][W];

int main(void) {
    // loop hoisting
    const int k00 = kernel3x3[0][0], k01 = kernel3x3[0][1], k02 = kernel3x3[0][2];
    const int k10 = kernel3x3[1][0], k11 = kernel3x3[1][1], k12 = kernel3x3[1][2];
    const int k20 = kernel3x3[2][0], k21 = kernel3x3[2][1], k22 = kernel3x3[2][2];
    for (int y = 1; y < H-1; y++) {
        const unsigned char *r0 = input_image[y-1];
        const unsigned char *r1 = input_image[y];
        const unsigned char *r2 = input_image[y+1];
        for (int x = 1; x < W-1; x++) {
            // loop unrolling
            int acc = 0;
            // address calculation simplfication
            acc += r0[x-1]*k00 + r0[x]*k01 + r0[x+1]*k02;
            acc += r1[x-1]*k10 + r1[x]*k11 + r1[x+1]*k12;
            acc += r2[x-1]*k20 + r2[x]*k21 + r2[x+1]*k22;
            out[y][x] = acc;
        }
    }
    sink = checksum_output(out);
    return sink == -36456 ? 0 : 1;
}
