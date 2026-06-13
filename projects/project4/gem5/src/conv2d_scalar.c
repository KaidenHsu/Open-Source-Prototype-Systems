#include "input_image.h"
#include "kernel.h"
#include "checksum.h"

volatile int sink;
int out[H][W];

int main(void) {
    for (int y = 1; y < H-1; y++) {
        for (int x = 1; x < W-1; x++) {
            int acc = 0;
            for (int ky = 0; ky < 3; ky++) {
                for (int kx = 0; kx < 3; kx++) {
                    acc += (int)input_image[y + ky - 1][x + kx - 1] * (int)kernel3x3[ky][kx];
                }
            }
            out[y][x] = acc;
        }
    }
    sink = checksum_output(out);
    return sink == -36456 ? 0 : 1;
}
