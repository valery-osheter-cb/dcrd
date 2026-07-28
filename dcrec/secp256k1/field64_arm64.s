// Copyright (c) 2026 The Decred developers
// Use of this source code is governed by an ISC
// license that can be found in the LICENSE file.

//go:build arm64 && !purego

#include "textflag.h"


// REDUCE folds the 512-bit product in R9..R16 modulo p = 2^256 - c
// (c = 0x1000003D1) into R1..R4 and stores them at r+0(FP).
#define REDUCE() \
    MOVD  $0x1000003D1, R17                                          \
    \
    MUL   R13, R17, R1;    UMULH R13, R17, R6                        \
    MUL   R14, R17, R7;    UMULH R14, R17, R8;    ADDS  R7, R6, R2   \
    ADC   R8,  ZR,  R6                                               \
    MUL   R15, R17, R7;    UMULH R15, R17, R8;    ADDS  R7, R6, R3   \
    ADC   R8,  ZR,  R6                                               \
    MUL   R16, R17, R7;    UMULH R16, R17, R8;    ADDS  R7, R6, R4   \
    ADC   R8,  ZR,  R5                                               \
    \
    ADDS  R9,  R1, R1                                                \
    ADCS  R10, R2, R2                                                \
    ADCS  R11, R3, R3                                                \
    ADCS  R12, R4, R4                                                \
    ADC   ZR,  R5, R5                                                \
    \
    MUL   R5, R17, R7;    UMULH R5, R17, R6                          \
    ADDS  R7, R1, R1                                                 \
    ADCS  R6, R2, R2                                                 \
    ADCS  ZR, R3, R3                                                 \
    ADCS  ZR, R4, R4                                                 \
    ADC   ZR, ZR, R5                                                 \
    \
    NEG   R17, R23      /* R23 = -c    = p[0]  (p = 2^256 - c)  */   \
    MVN   ZR,  R24      /* R24 = ^0    = p[1..3] (all ones)      */  \
    SUBS  R23, R1,  R19                                              \
    SBCS  R24, R2,  R20                                              \
    SBCS  R24, R3,  R21                                              \
    SBCS  R24, R4,  R22                                              \
    SBCS  ZR,  R5,  ZR                                               \
    CSEL  CS,  R19, R1, R1                                           \
    CSEL  CS,  R20, R2, R2                                           \
    CSEL  CS,  R21, R3, R3                                           \
    CSEL  CS,  R22, R4, R4                                           \
    \
    MOVD  r+0(FP), R0                                                \
    STP   (R1, R2), 0(R0)                                            \
    STP   (R3, R4), 16(R0)

// func field64Mul(r *[4]uint64, a, b *[4]uint64)
//
// Register usage during the multiply:
//   a limbs: R1..R4   b limbs: R5..R8   product p0..p7: R9..R16   scratch: R19..R23
TEXT ·field64Mul(SB), NOSPLIT, $0-24
    MOVD a+8(FP), R0
    LDP  0(R0), (R1, R2)
    LDP  16(R0), (R3, R4)
    MOVD b+16(FP), R0
    LDP  0(R0), (R5, R6)
    LDP  16(R0), (R7, R8)

    // 512-bit product of a (R1..R4) and b (R5..R8) into R9..R16, built one
    // b-limb at a time (fresh top limb doubles as the second UMULH scratch).
    UMULH R1,  R5, R23;   MUL   R1, R5, R9
    UMULH R2,  R5, R13;   MUL   R2, R5, R10;    ADDS  R23, R10, R10
    UMULH R3,  R5, R23;   MUL   R3, R5, R11;    ADCS  R13, R11, R11
    UMULH R4,  R5, R13;   MUL   R4, R5, R12;    ADCS  R23, R12, R12
    ADC   ZR,  R13, R13

    UMULH R1,  R6, R23;   MUL   R1, R6, R19
    UMULH R2,  R6, R14;   MUL   R2, R6, R20;    ADDS  R23, R20, R20
    UMULH R3,  R6, R23;   MUL   R3, R6, R21;    ADCS  R14, R21, R21
    UMULH R4,  R6, R14;   MUL   R4, R6, R22;    ADCS  R23, R22, R22
    ADC   ZR,  R14, R14
    ADDS  R19, R10, R10;  ADCS  R20, R11, R11;  ADCS  R21, R12, R12;  ADCS  R22, R13, R13
    ADC   ZR,  R14, R14

    UMULH R1,  R7, R23;   MUL   R1, R7, R19
    UMULH R2,  R7, R15;   MUL   R2, R7, R20;    ADDS  R23, R20, R20
    UMULH R3,  R7, R23;   MUL   R3, R7, R21;    ADCS  R15, R21, R21
    UMULH R4,  R7, R15;   MUL   R4, R7, R22;    ADCS  R23, R22, R22
    ADC   ZR,  R15, R15
    ADDS  R19, R11, R11;  ADCS  R20, R12, R12;  ADCS  R21, R13, R13;  ADCS  R22, R14, R14
    ADC   ZR,  R15, R15

    UMULH R1,  R8, R23;   MUL   R1, R8, R19
    UMULH R2,  R8, R16;   MUL   R2, R8, R20;    ADDS  R23, R20, R20
    UMULH R3,  R8, R23;   MUL   R3, R8, R21;    ADCS  R16, R21, R21
    UMULH R4,  R8, R16;   MUL   R4, R8, R22;    ADCS  R23, R22, R22
    ADC   ZR,  R16, R16
    ADDS  R19, R12, R12;  ADCS  R20, R13, R13;  ADCS  R21, R14, R14;  ADCS  R22, R15, R15
    ADC   ZR,  R16, R16

    REDUCE()
    RET

// func field64Square(r *[4]uint64, a *[4]uint64)
//
// Register usage: a limbs R1..R4, product p0..p7 R9..R16, scratch R19..R22.
TEXT ·field64Square(SB), NOSPLIT, $0-16
    MOVD a+8(FP), R0
    LDP  0(R0), (R1, R2)
    LDP  16(R0), (R3, R4)

    // Off-diagonal products (upper triangle), no doubling yet.
    MUL   R1, R2, R10;    UMULH R1, R2, R11

    MUL   R1,  R3, R19;   UMULH R1, R3, R12;    ADDS  R19, R11, R11
    MUL   R1,  R4, R20;   UMULH R1, R4, R13;    ADCS  R20, R12, R12
    ADC   ZR,  R13, R13

    MUL   R2,  R3, R19;   UMULH R2, R3, R20;    ADDS  R19, R12, R12
    ADCS  R20, R13, R13
    ADC   ZR,  ZR,  R14

    MUL   R2,  R4, R19;   UMULH R2, R4, R20;    ADDS  R19, R13, R13
    ADC   R20, R14, R14

    MUL   R3,  R4, R19;   UMULH R3, R4, R15;    ADDS  R19, R14, R14
    ADC   ZR,  R15, R15

    // Double p1..p6, capturing the top carry into p7.
    ADDS  R10, R10, R10
    ADCS  R11, R11, R11
    ADCS  R12, R12, R12
    ADCS  R13, R13, R13
    ADCS  R14, R14, R14
    ADCS  R15, R15, R15
    ADC   ZR,  ZR,  R16

    // Add the diagonal squares a[i]^2 at columns 0,2,4,6 in one carry chain.
    MUL   R1, R1, R9;    UMULH R1, R1, R21;    ADDS  R21, R10, R10

    MUL   R2,  R2, R21;  UMULH R2, R2, R22;    ADCS  R21, R11, R11
    ADCS  R22, R12, R12

    MUL   R3,  R3, R21;  UMULH R3, R3, R22;    ADCS  R21, R13, R13
    ADCS  R22, R14, R14

    MUL   R4,  R4, R21;  UMULH R4, R4, R22;    ADCS  R21, R15, R15
    ADC   R22, R16, R16

    REDUCE()
    RET
