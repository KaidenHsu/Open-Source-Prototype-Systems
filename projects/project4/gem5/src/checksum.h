#ifndef CHECKSUM_H
#define CHECKSUM_H
static int checksum_output(const int out[H][W]) {
    int sum = 0;
    for (int y = 1; y < H-1; y++) {
        for (int x = 1; x < W-1; x++) {
            sum += out[y][x] * (y + 3*x + 1);
        }
    }
    return sum;
}
#endif
