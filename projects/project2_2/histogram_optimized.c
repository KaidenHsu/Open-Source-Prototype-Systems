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

    int local_bins[BINS] = {0};
    for (int i = 0; i < N; i++) {
        uint8_t v = input_data[i];
        local_bins[v >> 4]++;
    }
    for (int i = 0; i < BINS; i++) bins[i] += local_bins[i];

    volatile int checksum = 0;
    for (int i = 0; i < BINS; i++) checksum += bins[i] * (i + 1);
    printf("optimized checksum=%d\n", checksum);
    return checksum & 0xFF;
}
