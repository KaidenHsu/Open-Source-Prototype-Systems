#include <stdint.h> 
#include <stdio.h> 
#include "xhist_intrin.h" 
 
int main(void) 
{ 
    uint64_t a = 0x1234; 
    uint64_t b = 0xabcd; 
    uint64_t r = xhpack(a, b); 
    printf("xhpack result: 0x%lx\n", r); 
    return 0; 
} 
