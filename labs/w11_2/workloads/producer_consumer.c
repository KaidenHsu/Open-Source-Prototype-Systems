// Two-core producer-consumer workload for gem5 SE mode.
//
// Design choice: use exactly one pthread plus the main thread.
// The main thread runs the consumer role. The created pthread runs the producer
// role. This avoids the earlier failure caused by trying to create two worker
// pthreads on a two-CPU SE-mode configuration.
//
// The synchronization object is process-local shared memory. The producer
// publishes data first, then publishes a ready flag using release semantics.
// The consumer waits on the ready flag using acquire semantics, then checks the
// data. This makes the workload a compact architecture-level demonstration of
// producer-consumer visibility without relying on host files or unsupported
// syscalls such as renameat2.

#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

static volatile uint64_t mailbox_sum = 0;
static volatile int mailbox_iters = 0;
static volatile int mailbox_ready = 0;

static int g_iterations = 2048;

static uint64_t expected_sum(int n) {
    return ((uint64_t)n * (uint64_t)(n + 1)) / 2u;
}

// A busy-wait loop that performs pseudo-random computations to
// simulate work and introduce delays without blocking or sleeping.
static void deterministic_delay(volatile uint64_t rounds) {
    // volatile prevents compiler optimization
    volatile uint64_t x = 0x12345678u;

    // Linear Congruential Generator (LCG) algorithm
    for (volatile uint64_t i = 0; i < rounds; i++) {
        x = (x * 1103515245u + 12345u) ^ (x >> 7);
    }
    
    // silences unused variable warning
    (void)x;
}

static void *producer_thread(void *arg) {
    int iterations = *(int *)arg;
    uint64_t sum = 0;

    for (int i = 1; i <= iterations; i++) {
        sum += (uint64_t)i;
        if ((i & 63) == 0) deterministic_delay(32);
    }

    // Publish payload before publishing the ready flag.
    __atomic_store_n(&mailbox_sum, sum, __ATOMIC_RELAXED);
    __atomic_store_n(&mailbox_iters, iterations, __ATOMIC_RELAXED);
    __atomic_store_n(&mailbox_ready, 1, __ATOMIC_RELEASE);

    printf("PRODUCER role=producer iterations=%d sum=%llu\n",
           iterations, (unsigned long long)sum);
    return NULL;
}

static int run_consumer(int iterations) {
    const int max_polls = 2000000;

    int ready = 0;
    for (int p = 0; p < max_polls; p++) {
        ready = __atomic_load_n(&mailbox_ready, __ATOMIC_ACQUIRE);
        if (ready) break;
        if ((p & 255) == 0) deterministic_delay(16);
    }

    if (!ready) {
        printf("PRODUCER_CONSUMER FAIL: consumer timeout waiting for ready flag\n");
        return 2;
    }

    uint64_t observed_sum = __atomic_load_n(&mailbox_sum, __ATOMIC_RELAXED);
    int observed_iters = __atomic_load_n(&mailbox_iters, __ATOMIC_RELAXED);
    uint64_t expected = expected_sum(iterations);

    printf("CONSUMER role=consumer iterations=%d observed_iters=%d observed_sum=%llu expected=%llu\n",
           iterations, observed_iters, (unsigned long long)observed_sum,
           (unsigned long long)expected);

    if (observed_iters == iterations && observed_sum == expected) {
        printf("PRODUCER_CONSUMER PASS\n");
        return 0;
    }

    printf("PRODUCER_CONSUMER FAIL\n");
    return 1;
}

int main(int argc, char **argv) {
    if (argc >= 2) {
        g_iterations = atoi(argv[1]);
        if (g_iterations <= 0) g_iterations = 2048;
    }

    pthread_t producer;

    int rc = pthread_create(&producer, NULL, producer_thread, &g_iterations);
    if (rc != 0) {
        printf("PRODUCER_CONSUMER FAIL: pthread_create rc=%d\n", rc);
        return 10;
    }

    int result = run_consumer(g_iterations);

    // wait for both producer and consumer to finish execution
    rc = pthread_join(producer, NULL);
    if (rc != 0) {
        printf("PRODUCER_CONSUMER FAIL: pthread_join rc=%d\n", rc);
        return 11;
    }

    return result;
}
