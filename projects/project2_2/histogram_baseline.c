#include <stdint.h>
#include <stdio.h>

#define N 4096
#define BINS 16

static uint8_t input_data[N];
static int bins[BINS];

static void init_data(void) {
    for (int i = 0; i < N; i++) {
        input_data[i] = (uint8_t)((i * 37 + 13) & 0xFF);
    }
    for (int i = 0; i < BINS; i++) bins[i] = 0;
}

int main(void) {
    init_data();

    for (int i = 0; i < N; i++) {
        uint8_t v = input_data[i];
        if (v < 16) bins[0]++;
        else if (v < 32) bins[1]++;
        else if (v < 48) bins[2]++;
        else if (v < 64) bins[3]++;
        else if (v < 80) bins[4]++;
        else if (v < 96) bins[5]++;
        else if (v < 112) bins[6]++;
        else if (v < 128) bins[7]++;
        else if (v < 144) bins[8]++;
        else if (v < 160) bins[9]++;
        else if (v < 176) bins[10]++;
        else if (v < 192) bins[11]++;
        else if (v < 208) bins[12]++;
        else if (v < 224) bins[13]++;
        else if (v < 240) bins[14]++;
        else bins[15]++;
    }

    volatile int checksum = 0;
    for (int i = 0; i < BINS; i++) checksum += bins[i] * (i + 1);
    printf("baseline checksum=%d\n", checksum);
    return checksum & 0xFF;
}
