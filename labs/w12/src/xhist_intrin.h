#ifndef XHIST_INTRIN_H
#define XHIST_INTRIN_H

#include <stdint.h>

static inline uint64_t xhrange(uint64_t value, uint64_t cfg)
{
    uint64_t rd;
    asm volatile (".insn r 0x0b, 0x0, 0x01, %0, %1, %2"
                  : "=r"(rd)
                  : "r"(value), "r"(cfg));
    return rd;
}

static inline uint64_t xhbin(uint64_t value, uint64_t cfg)
{
    uint64_t rd;
    asm volatile (".insn r 0x0b, 0x1, 0x01, %0, %1, %2"
                  : "=r"(rd)
                  : "r"(value), "r"(cfg));
    return rd;
}

static inline uint64_t xhsat(uint64_t value, uint64_t limit)
{
    uint64_t rd;
    asm volatile (".insn r 0x0b, 0x2, 0x01, %0, %1, %2"
                  : "=r"(rd)
                  : "r"(value), "r"(limit));
    return rd;
}

static inline uint64_t xhpack(uint64_t a, uint64_t b)
{
    uint64_t rd;
    asm volatile (".insn r 0x0b, 0x3, 0x01, %0, %1, %2"
                  : "=r"(rd)
                  : "r"(a), "r"(b));
    return rd;
}

// my proposed custom instruction
static inline uint64_t xhbinclip(uint64_t a, uint64_t b)
{
    uint64_t rd;
    asm volatile (".insn r 0x0b, 0x4, 0x02, %0, %1, %2"
                  : "=r"(rd)
                  : "r"(a), "r"(b));
    return rd;
}

#endif
