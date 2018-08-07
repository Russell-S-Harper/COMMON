#include "common.h"

#ifndef MACROS_H
#define MACROS_H

; registers
#define	R0		0
#define	R1		1
#define	R2		2
#define	R3		3
#define	R4		4
#define	R5		5
#define	R6		6
#define	R7		7
#define	R8		8
#define	R9		9
#define	RA		10
#define	RB		11
#define	RC		12
#define	RD		13
#define	RE		14
#define	RF		15

; system functions
#define	S0		0
#define	S1		1
#define	S2		2
#define	S3		3
#define	S4		4
#define	S5		5
#define	S6		6
#define	S7		7
#define	S8		8
#define	S9		9
#define	SA		10
#define	SB		11
#define	SC		12
#define	SD		13
#define	SE		14
#define	SF		15

; user functions
#define	U0		15
#define	U1		14
#define	U2		13
#define	U3		12
#define	U4		11
#define	U5		10
#define	U6		9
#define	U7		8
#define	U8		7
#define	U9		6
#define	UA		5
#define	UB		4
#define	UC		3
#define	UD		2
#define	UE		1
#define	UF		0

; macros
#define ESC		.BYTE _ESC_C
#define RTN		.BYTE _RTN_C
#define BRS(o)		.BYTE _BRS_C, <(o - * - 3), >(o - * - 3)
#define BRA(o)		.BYTE _BRA_C, <(o - * - 3), >(o - * - 3)
#define BRE(o)		.BYTE _BRE_C, <(o - * - 3), >(o - * - 3)
#define BRG(o)		.BYTE _BRG_C, <(o - * - 3), >(o - * - 3)
#define BRL(o)		.BYTE _BRL_C, <(o - * - 3), >(o - * - 3)
#define BRZ(o)		.BYTE _BRZ_C, <(o - * - 3), >(o - * - 3)
#define BRP(o)		.BYTE _BRP_C, <(o - * - 3), >(o - * - 3)
#define BRN(o)		.BYTE _BRN_C, <(o - * - 3), >(o - * - 3)
#define BRO(o)		.BYTE _BRO_C, <(o - * - 3), >(o - * - 3)
#define BRU(o)		.BYTE _BRU_C, <(o - * - 3), >(o - * - 3)
#define CPR(p, q)	.BYTE _CPR_C, p * 16 + q
#define LDI(p, q)	.BYTE _LDI_C, p * 16 + q
#define SVI(p, q)	.BYTE _SVI_C, p * 16 + q
#define CMR(p, q)	.BYTE _CMR_C, p * 16 + q
#define SET(r, v)	.BYTE _SET_C + r, _SET_V(#v)
#define POP(r)		.BYTE _POP_C + r
#define PSH(r)		.BYTE _PSH_C + r
#define EXC(r)		.BYTE _EXC_C + r
#define INR(r)		.BYTE _INR_C + r
#define DCR(r)		.BYTE _DCR_C + r
#define TST(r)		.BYTE _TST_C + r
#define DEC(r)		.BYTE _DEC_C + r
#define HEX(r)		.BYTE _HEX_C + r
#define ADD(r)		.BYTE _ADD_C + r
#define SUB(r, p, q)	.BYTE _SUB_C + r, p * 16 + q
#define MUL(r, p, q)	.BYTE _MUL_C + r, p * 16 + q
#define DIV(r, p, q)	.BYTE _DIV_C + r, p * 16 + q
#define MOD(r, p, q)	.BYTE _MOD_C + r, p * 16 + q
#define EXT(f)		.BYTE _EXT_C + f

; header, begin and end of blocks
#define HDR(a)		.WORD a, _END_##a - a:* = * - 4:a .(
#define BGN(a)		a .(
#define END(a)		.):_END_##a

#endif // MACROS_H