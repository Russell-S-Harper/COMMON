#ifndef __COMMON_H
#define __COMMON_H

; Using four byte quantities aabbccdd with sign bit, overflow bit, 20 bits significand, 10 bits
; fraction. The quantity is valid if the overflow bit agrees with the sign bit. The intent is
; to be able to recognize an overflow/underflow situation, rescale the arguments, and repeat the
; calculation.

;  Largest value: $3fffffff or +1048575.999(5)
;       Plus one: $00000400
;           Zero: $00000000
;      Minus one: $fffffc00
; Smallest value: $c0000000 or -1048576.000(0)

; Instructions

; SET r aabbcc.dd	1r dd cc bb aa	Rr <- aabbccdd	- set register
; LDD r xxyy		2r yy xx	Rr <- (xxyy)	- load register directly from address
; SVD r xxyy		3r yy xx	(xxyy) <- Rr	- save register directly to address
; PSH r			4r		RS <- Rr	- push onto stack
; POP r			5r		Rr <- RS	- pop from stack
; EXC r			6r		Rr <-> RS	- exchange Rr with stack
; INR r			7r		Rr <- Rr + 1.0	- increment register
; DCR r			8r		Rr <- Rr - 1.0	- decrement register
; TST r			9r		F <- Rr <=> 0.0	- test register
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

; 40 bytes in page zero for common registers
_R0	= $100 - 4 * (10 + 10)
_R1	= _R0 + 4
_R2	= _R1 + 4
_R3	= _R2 + 4
_R4	= _R3 + 4
_R5	= _R4 + 4
_R6	= _R5 + 4
_R7	= _R6 + 4
_R8	= _R7 + 4
_R9	= _R8 + 4

; 40 bytes in page zero for internal registers
_I0	= _R9 + 4			; workspace
_I1	= _I0 + 4
_I2	= _I1 + 4
_I3	= _I2 + 4
_I4	= _I3 + 4
_I5	= _I4 + 4
_I6	= _I5 + 4			; register I6 maintains common status
_I7	= _I6 + 4			; register I7 maintains locations of process and allocated memory
_I8	= _I7 + 4			; register I8 maintains process information for context switching
_I9	= _I8 + 4			; register I9 saves/restores processor status

; register I6 maintains common status
; (dd cc bb aa) aa: index for register stack RS / ccbb: program counter PC / dd: flags F UONPZLGE
_RSI	= _I6				; register stack index
_PCL	= _RSI + 1			; program counter low
_PCH	= _PCL + 1			; program counter high
_F	= _PCH + 1			; flags
_PC	= _PCL				; program counter

; bits for flags
_F_E	=   1				; if Rp = Rq (after CMP)
_F_G	=   2				; if Rp > Rq (after CMP)
_F_L	=   4				; if Rp < Rq (after CMP)
_F_Z	=   8				; if Rr = 0.0 (after TST)
_F_P	=  16				; if Rr > 0.0 (after TST)
_F_N	=  32				; if Rr < 0.0 (after TST)
_F_O	=  64				; if overflow (after arithmetic operations)
_F_U	= 128				; if underflow (after arithmetic operations)

; register I7 maintains locations of code and allocated real memory addresses
_CRL	= _I7				; code low and high bytes
_CRH	= _CRL + 1
_ARL	= _CRH + 1			; allocated low and high bytes
_ARH	= _ARL + 1
_CR	= _CRL				; code real memory address
_AR	= _ARL				; allocated real memory address

; register I8 maintains process information for context switching
_PST	= _I8				; current process status
_PSI	= _PST + 1			; process stack index to save/restore
_PSO	= _PSI + 1			; offset to running processes table
_PSF	= _PSO + 1			; initial running process status PPPCCCLF

; register I9 saves/restores processor status
; (dd cc bb aa) aa: accumulator, bb: index X, cc: index Y, dd: processor status
_ACC	= _I9				; saved accumulator to restore
_IDX	= _ACC + 1			; saved index X to restore
_IDY	= _IDX + 1			; saved index Y to restore
_PS	= _IDY + 1			; saved processor status to restore

; 6502 stack resides on page one

; using some of page two for register stack
_RS	= $200				; register stack
_RSS	= _R0				; register stack size

; for context switching, _R0 to _RS + _RSS - 1 needs to be saved and restored
; this should comprise two pages or 512 bytes

; the following are common process table and system & user functions

; process information in the middle of page two
_RP	= _RS + _RSS			; running processes table
_RPS	= FN_FX - _RP			; running process table size

; process information indices
_RPV_I	= 0				; 4 bytes virtual memory address
_RPR_I	= _RPV_I + 4			; 2 bytes real memory address
_RPS_I	= _RPR_I + 2			; 1 byte size of program (in pages) including allocated memory
_RPF_I	= _RPS_I + 1			; 1 byte status PPPCCCLF / P priority / C counter / L loaded / F finished

_RPE	= _RPF_I + 1			; size of running process entry
_RPL	= _RPS / _RPE			; number of running processes limit

; last 32 bytes of page two
FN_FX	= $300 - 2 * 16			; list of system and user functions

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
_LDD_C	= $20
_SVD_C	= $30
_PSH_C	= $40
_POP_C	= $50
_EXC_C	= $60
_INR_C	= $70
_DCR_C	= $80
_TST_C	= $90
_ADD_C	= $a0
_SUB_C	= $b0
_MUL_C	= $c0
_DIV_C	= $d0
_MOD_C	= $e0
_EXT_C	= $f0

; common constants
_MSK_O	= %11000000			; mask for overflow
_MSK_R	= %00111100			; mask for registers
_MSK_T	= (_F_Z + _F_P + _F_N) ^ $ff	; mask for TST
_MSK_C	= (_F_E + _F_G + _F_L) ^ $ff	; mask for CMP

#endif /* __COMMON_H */
