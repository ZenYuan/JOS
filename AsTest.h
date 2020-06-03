#ifndef _ASTEST_H
#define _ASTEST_H

#define times3(arg1, arg2) \
__asm__ ( \
    "leal (%0, %0, 2), %0" \
    : "=r"(arg2) \
    : "0"(arg1) );

#define times5(arg1, arg2) \
__asm__( \
    "leal (%0, %0, 4), %0" \
    :"=r"(arg2) \
    :"0"(arg1) );

#define times9(arg1, arg2) \
__asm__( \
    "leal (%1, %1, 8), %1" \
    :"=q"(arg2) \
    :"0"(arg1) );

//test git
#endif

