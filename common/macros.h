#include "common.h"

#ifndef __MACROS_H
#define __MACROS_H

; common registers
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

; shorthand
#define	_OFF_M(o)	((o) - * - 3)
#define _BRX_M(o)	<_OFF_M(o), >_OFF_M(o)
#define	_MRG_M(p, q)	(p) * 16 + (q)

; macros
#define ESC		.BYTE _ESC_C
#define RTN		.BYTE _RTN_C
#define BRS(o)		.BYTE _BRS_C, _BRX_M(o)
#define BRA(o)		.BYTE _BRA_C, _BRX_M(o)
#define BRE(o)		.BYTE _BRE_C, _BRX_M(o)
#define BRG(o)		.BYTE _BRG_C, _BRX_M(o)
#define BRL(o)		.BYTE _BRL_C, _BRX_M(o)
#define BRZ(o)		.BYTE _BRZ_C, _BRX_M(o)
#define BRP(o)		.BYTE _BRP_C, _BRX_M(o)
#define BRN(o)		.BYTE _BRN_C, _BRX_M(o)
#define BRO(o)		.BYTE _BRO_C, _BRX_M(o)
#define BRU(o)		.BYTE _BRU_C, _BRX_M(o)
#define CPR(p, q)	.BYTE _CPR_C, _MRG_M(p, q)
#define LDI(p, q)	.BYTE _LDI_C, _MRG_M(p, q)
#define SVI(p, q)	.BYTE _SVI_C, _MRG_M(p, q)
#define CMR(p, q)	.BYTE _CMR_C, _MRG_M(p, q)
#define SET(r, v)	.BYTE _SET_C + (r), _SET_V(#v)
#define LDD(r, a)	.BYTE _LDD_C + (r), <(a), >(a)
#define SVD(r, a)	.BYTE _SVD_C + (r), <(a), >(a)
#define PSH(r)		.BYTE _PSH_C + (r)
#define POP(r)		.BYTE _POP_C + (r)
#define EXC(r)		.BYTE _EXC_C + (r)
#define INR(r)		.BYTE _INR_C + (r)
#define DCR(r)		.BYTE _DCR_C + (r)
#define TST(r)		.BYTE _TST_C + (r)
#define ADD(r, p, q)	.BYTE _ADD_C + (r), _MRG_M(p, q)
#define SUB(r, p, q)	.BYTE _SUB_C + (r), _MRG_M(p, q)
#define MUL(r, p, q)	.BYTE _MUL_C + (r), _MRG_M(p, q)
#define DIV(r, p, q)	.BYTE _DIV_C + (r), _MRG_M(p, q)
#define MOD(r, p, q)	.BYTE _MOD_C + (r), _MRG_M(p, q)
#define EXT(f)		.BYTE _EXT_C + (f)

; header, begin and end of blocks
#define HDR(a)		.WORD a, _END_##a - a:* = * - 4:a .(
#define BGN(a)		a .(
#define END(a)		.):_END_##a

#endif /* __MACROS_H */
