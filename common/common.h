#ifndef __COMMON_H
#define __COMMON_H

; Using four byte quantities aabbccdd with sign bit, overflow bit, 20 bits significand, 10 bits
; fraction. The quantity is valid if the overflow bit agrees with the sign bit. The intent is
; to be able to recognize an overflow/underflow situation, rescale the arguments, and repeat the
; calculation.

; Largest value:              $3fffffff or  1048575.999(5)
; Smallest value:             $c0000000 or -1048576.000(0)
; Largest value for DEC/HEX:  $3d08ffff or   999999.999
; Smallest value for DEC/HEX: $c2f70001 or  -999999.999

; Instructions

; SET r aabbcc.dd	1r dd cc bb aa	Rr <- aabbccdd	- set register
; PSH r			2r		RS <- Rr	- push onto stack
; POP r			3r		Rr <- RS	- pop from stack
; EXC r			4r		Rr <-> RS	- exchange Rr with stack
; INR r			5r		Rr <- Rr + 1.0	- increment register
; DCR r			6r		Rr <- Rr - 1.0	- decrement register
; TST r			7r		F <- Rr <=> 0.0	- test register
; DEC r			8r		Rr <- dec(Rr)	- convert Rr from hex aabbccdd to decimal #########
; HEX r			9r		Rr <- hex(Rr)	- convert Rr from decimal ######### to hex aabbccdd
; ADD r pq		ar pq		Rr <- Rp + Rq	- addition
; SUB r pq		br pq		Rr <- Rp - Rq	- subtraction
; MUL r pq		cr pq		Rr <- Rp * Rq	- multiplication
; DIV r pq		dr pq		Rr <- Rp / Rq	- division
; MOD r pq		er pq		Rr <- Rp % Rq	- modulus
; EXT z	...		fz ...				- system and user defined functions

; ESC			00				- escape back into regular assembler
; RTN			01				- return from subroutine
; BRS xxyy		02 yy xx	PC <- PC + xxyy	- branch to subroutine
; BRA xxyy		03 yy xx	PC <- PC + xxyy	- branch always
; BRE xxyy		04 yy xx	PC <- PC + xxyy	- branch if Rp = Rq (after CMR)
; BRG xxyy		05 yy xx	PC <- PC + xxyy	- branch if Rp > Rq (after CMR)
; BRL xxyy		06 yy xx	PC <- PC + xxyy	- branch if Rp < Rq (after CMR)
; BRZ xxyy		07 yy xx	PC <- PC + xxyy	- branch if Rr = 0.0 (after TST)
; BRP xxyy		08 yy xx	PC <- PC + xxyy	- branch if Rr > 0.0 (after TST)
; BRN xxyy		09 yy xx	PC <- PC + xxyy	- branch if Rr < 0.0 (after TST)
; BRO xxyy		0a yy xx	PC <- PC + xxyy	- branch if overflow (after arithmetic operations)
; BRU xxyy		0b yy xx	PC <- PC + xxyy	- branch if underflow (after arithmetic operations)
; CPR pq		0c pq		Rp <- Rq	- copy register
; LDI pq		0d pq		Rp <- (int(Rq))	- load indirect from memory
; SVI pq		0e pq		(int(Rp)) <- Rq	- save indirect to memory
; CMR pq		0f pq		F <- Rp <=> Rq	- compare registers

; 64 bytes in page zero for common registers
_R0	= $c0
_R1	= _R0 + 4
_R2	= _R1 + 4
_R3	= _R2 + 4
_R4	= _R3 + 4
_R5	= _R4 + 4
_R6	= _R5 + 4
_R7	= _R6 + 4
_R8	= _R7 + 4
_R9	= _R8 + 4
_RA	= _R9 + 4
_RB	= _RA + 4	; workspace for MUL, DIV, and MOD
_RC	= _RB + 4	; as above
_RD	= _RC + 4	; as above and for ADD, SUB, and EXC
_RE	= _RD + 4	; register E maintains common status
_RF	= _RE + 4	; register F saves/restores processor status

; register E maintains common status
; (dd cc bb aa) aa: index for register stack RS / ccbb: program counter PC / dd: flags F UONPZLGE
_RSI	= _RE		; register stack index
_PCL	= _RSI + 1	; program counter low
_PCH	= _PCL + 1	; program counter high
_F	= _PCH + 1	; flags
_PC	= _PCL		; program counter

; bits for flags
_F_E	=   1		; if Rp = Rq (after CMP)
_F_G	=   2		; if Rp > Rq (after CMP)
_F_L	=   4		; if Rp < Rq (after CMP)
_F_Z	=   8		; if Rr = 0.0 (after TST)
_F_P	=  16		; if Rr > 0.0 (after TST)
_F_N	=  32		; if Rr < 0.0 (after TST)
_F_O	=  64		; if overflow (after arithmetic operations)
_F_U	= 128		; if underflow (after arithmetic operations)

; register F saves/restores processor status
; (dd cc bb aa) aa: accumulator, bb: index X, cc: index Y, dd: processor status
_ACC	= _RF		; saved accumulator to restore
_IDX	= _ACC + 1	; saved index X to restore
_IDY	= _IDX + 1	; saved index Y to restore
_PS	= _IDY + 1	; saved processor status to restore

; 224 bytes of page two
_RS	= $200		; register stack
_RSS	= (FN_FX - _RS)	; register stack size

; last 32 bytes of page two
FN_FX	= $2e0		; list of system and user functions

; function constants
_ESC_C	= $00
_RTN_C	= $01
_BRS_C	= $02
_BRA_C	= $03
_BRE_C	= $04
_BRG_C	= $05
_BRL_C	= $06
_BRZ_C	= $07
_BRP_C	= $08
_BRN_C	= $09
_BRO_C	= $0a
_BRU_C	= $0b
_CPR_C	= $0c
_LDI_C	= $0d
_SVI_C	= $0e
_CMR_C	= $0f

_SET_C	= $10
_PSH_C	= $20
_POP_C	= $30
_EXC_C	= $40
_INR_C	= $50
_DCR_C	= $60
_TST_C	= $70
_DEC_C	= $80
_HEX_C	= $90
_ADD_C	= $a0
_SUB_C	= $b0
_MUL_C	= $c0
_DIV_C	= $d0
_MOD_C	= $e0
_EXT_C	= $f0

; common constants

; plus and minus 1 for increment and decrement
_PLS_1	= %00000100	; i.e. the $04 part of $00000400
_MNS_1	= %11111100	; i.e. the $fc part of $fffffc00

_MSK_O	= %11000000	; mask for overflow
_MSK_R	= %00111100	; mask for registers

; mask for TST
_MSK_T	= (_F_Z + _F_P + _F_N)^$ff

#endif /* __COMMON_H */
