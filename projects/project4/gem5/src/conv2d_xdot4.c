#include "input_image.h"
#include "kernel.h"
#include "checksum.h"

volatile int sink;
int out[H][W];

static inline int pack4_u8(unsigned char a0, unsigned char a1, unsigned char a2, unsigned char a3) {
    return ((int)a0 & 0xff) | (((int)a1 & 0xff) << 8) | (((int)a2 & 0xff) << 16) | (((int)a3 & 0xff) << 24);
}

static inline int pack4_s8(signed char a0, signed char a1, signed char a2, signed char a3) {
    return ((int)(unsigned char)a0) | (((int)(unsigned char)a1) << 8) | (((int)(unsigned char)a2) << 16) | (((int)(unsigned char)a3) << 24);
}

static inline int xdot4(int packed_pixels, int packed_coeffs) {

    // TODO: Replace this fallback with the custom instruction wrapper after adding xdot4 to gem5.
    // Suggested encoding form for a custom-0 R-type instruction is provided in gem5/patches/.
    // int rd;
    // signed char p0 = (signed char)(packed_pixels & 0xff);
    // signed char p1 = (signed char)((packed_pixels >> 8) & 0xff);
    // signed char p2 = (signed char)((packed_pixels >> 16) & 0xff);
    // signed char p3 = (signed char)((packed_pixels >> 24) & 0xff);
    // signed char k0 = (signed char)(packed_coeffs & 0xff);
    // signed char k1 = (signed char)((packed_coeffs >> 8) & 0xff);
    // signed char k2 = (signed char)((packed_coeffs >> 16) & 0xff);
    // signed char k3 = (signed char)((packed_coeffs >> 24) & 0xff);
    // rd = p0*k0 + p1*k1 + p2*k2 + p3*k3;

    // zero-extend to 64-bit
    long rs1 = (unsigned int)packed_pixels;
    long rs2 = (unsigned int)packed_coeffs;
    long rd;

    asm volatile (".insn r 0x0b, 0x0, 0x01, %0, %1, %2"
                  : "=r"(rd)
                  : "r"(rs1), "r"(rs2));
    return (int)rd;
}

int main(void) {
    for (int y = 1; y < H-1; y++) {
        for (int x = 1; x < W-1; x++) {
            int p0 = pack4_u8(input_image[y-1][x-1], input_image[y-1][x], input_image[y-1][x+1], input_image[y][x-1]);
            int k0 = pack4_s8(kernel3x3[0][0], kernel3x3[0][1], kernel3x3[0][2], kernel3x3[1][0]);
            int p1 = pack4_u8(input_image[y][x], input_image[y][x+1], input_image[y+1][x-1], input_image[y+1][x]);
            int k1 = pack4_s8(kernel3x3[1][1], kernel3x3[1][2], kernel3x3[2][0], kernel3x3[2][1]);
            int acc = xdot4(p0, k0) + xdot4(p1, k1);
            acc += (int)input_image[y+1][x+1] * (int)kernel3x3[2][2];
            out[y][x] = acc;
        }
    }
    sink = checksum_output(out);
    return sink == -36456 ? 0 : 1;
}
