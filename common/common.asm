#include "rom.h"
#include "common.h"

	; ROM code header
	.WORD CMN_CD, _END_CMN_CD - CMN_CD

	; beginning of ROM code
	* = CMN_CD

_CMN	.(		; common function interpreter
	JSR _SAV	; save registers
	PLA
	STA _PCL	; set program counter from return address
	PLA
	STA _PCH
	INC _PCL	; advance the program counter
	BNE _1
	INC _PCH
_1	JSR _2		; interpret and execute one common instruction
	JMP _1
_2	LDY #0
	LDA (_PC),Y	; get operand
	INC _PCL	; advance the program counter
	BNE _3
	INC _PCH
_3	TAX		; save operand for later
	AND #$F0
	BEQ _4		; go to 0X instructions
	CMP #$F0	; check for FX functions
	BEQ _5		; go to FX instructions
	LSR		; get offset to XR instructions
	LSR
	LSR
	TAY
	DEY
	DEY
	LDA FN_XR+1,Y	; push high address
	PHA
	LDA FN_XR,Y	; push low address
	PHA
	TXA		; restore operand
	AND #$F		; mask to get register
	ASL		; shift to get offset to register
	ASL
	TAX		; back to index
	RTS		; "return" to routine	
_4	TXA		; get operand
	ASL		; shift to get offset to 0X instructions
	TAY
	LDA FN_0X+1,Y	; push high address
	PHA
	LDA FN_0X,Y	; push low address
	PHA
	TXA		; restore operand
	RTS		; "return" to routine	
_5	TXA		; get operand
	AND #$F		; mask to get index
	ASL		; shift to get offset to FX instructions
	TAY
	LDA FN_FX+1,Y	; push high address
	PHA
	LDA FN_FX,Y	; push low address
	PHA
	TXA		; restore operand
	RTS		; "return" to routine
.)

_INI	.(		; initialize common
	LDA #0		; initialize RSI
	STA _RSI
			; copy system functions (TODO)
			; load program (TODO)
	JMP (_PC)	; go to last loaded block
.)

_SAV	.(		; save the registers prior to entering common
	STA _ACC
	STX _IDX
	STY _IDY
	PHP
	PLA
	STA _PS
	CLD
	RTS
.)

_RES	.(		; restore the registers prior to leaving common
	LDA _PS
	PHA
	LDA _ACC
	LDX _IDX
	LDY _IDY
	PLP
	RTS
.)

_SET	.(		; SET r aabbcc.dd	1r dd cc bb aa	Rr <- aabbcc.dd	- set register
	LDY #0
	LDA (_PC),Y	; transfer four bytes over
	STA _R0,X
	INY
	LDA (_PC),Y
	STA _R0+1,X
	INY
	LDA (_PC),Y
	STA _R0+2,X
	INY
	LDA (_PC),Y
	STA _R0+3,X
	LDA #4		; update program counter
	CLC
	ADC _PCL
	STA _PCL
	BCC _1
	INC _PCH
_1	RTS		; done
.)

_PSH	.(		; PSH r			2r		RS <- Rr	- push onto stack
	LDY _RSI	; get register stack index
	CPY #_RSS	; compare against limit
	BCC _1		; still room, all okay
	BRK		; next push will cause a stack overflow, abort and call exception handler (TODO)
_1	LDA _R0,X	; transfer four bytes over
	STA _RS,Y
	INY
	LDA _R0+1,X
	STA _RS,Y
	INY
	LDA _R0+2,X
	STA _RS,Y
	INY
	LDA _R0+3,X
	STA _RS,Y
	INY
	STY _RSI	; update register stack index
	RTS
.)

_POP	.(		; POP r			3r		Rr <- RS	- pop from stack
	LDY _RSI	; get register stack index
	BNE _1		; all good, something can be popped off the stack
	BRK		; next pop will cause a stack underflow, abort and call exception handler (TODO)
_1	DEY		; transfer four bytes over
	LDA _RS,Y
	STA _R0+3,X
	DEY
	LDA _RS,Y
	STA _R0+2,X
	DEY
	LDA _RS,Y
	STA _R0+1,X
	DEY
	LDA _RS,Y
	STA _R0,X
	STY _RSI	; update register stack index
	RTS
.)

_EXC	.(		; EXC r			4r		Rr <-> RS	- exchange Rr with stack
	LDY _RSI	; RS to RD
	LDA _RS-1,Y
	STA _RD+3
	LDA _RS-2,Y
	STA _RD+2
	LDA _RS-3,Y
	STA _RD+1
	LDA _RS-4,Y
	STA _RD
	LDA _R0,X	; copy Rr to RS
	STA _RS-4,Y
	LDA _R0+1,X
	STA _RS-3,Y
	LDA _R0+2,X
	STA _RS-2,Y
	LDA _R0+3,X
	STA _RS-1,Y
	LDA _RD		; copy RD to Rr
	STA _R0,X
	LDA _RD+1
	STA _R0+1,X
	LDA _RD+2
	STA _R0+2,X
	LDA _RD+3
	STA _R0+3,X
	RTS
.)

_ADDRD	.(		; add RD to register indexed by X
	LDA _R0+3,X
	AND #_MSK_O	; check for existing overflow condition
	BEQ _4
	EOR #_MSK_O
	BNE _3		; existing overflow, skip decrement operation
_4	CLC		; adding RD
	LDA _RD
	ADC _R0,X
	STA _R0,X
	LDA _RD+1
	ADC _R0+1,X
	STA _R0+1,X
	LDA _RD+2
	ADC _R0+2,X
	STA _R0+2,X
	LDA _RD+3
	ADC _R0+3,X
	STA _R0+3,X
	AND #_MSK_O	; check for overflow
	BEQ _2
	EOR #_MSK_O
	BEQ _2
_3	LDA _F		; set overflow
	ORA #_F_O
	STA _F
	BNE _5
_2	LDA _F		; clear overflow
	AND #_F_O^$FF
	STA _F
_5	RTS
.)

_INR	.(		; INR r			5r		Rr <- Rr + 1.0	- increment register
	LDA #0		; set RD to plus one
	STA _RD
	LDA #_PLS_1
	STA _RD+1
	LDA #0
	STA _RD+2
	STA _RD+3
	BEQ _ADDRD
.)

_DCR	.(		; DCR r			6r		Rr <- Rr - 1.0	- decrement register
	LDA #0		; set RD to minus one
	STA _RD
	LDA #_MNS_1
	STA _RD+1
	LDA #$FF
	STA _RD+2
	STA _RD+3
	BNE _ADDRD
.)

_TST	.(		; TST r			7r		F <- Rr <=> 0.0	- test register
	LDA _F
	AND #_MSK_T	; clear TST bits
	STA _F
	LDA _R0+3,X	; check highest byte
	BMI _1		; is negative
	ORA _R0+2,X	; could be positive or zero, OR with all other bytes
	ORA _R0+1,X
	ORA _R0,X
	BNE _2		; is positive
	LDA #_F_Z	; set zero flag
	BNE _3
_1	LDA #_F_N	; set negative flag
	BNE _3
_2	LDA #_F_P	; set positive flag
_3	ORA _F
	STA _F
	RTS
.)

_DEC	.(		; DEC r			8r		Rr <- dec(Rr)	- convert Rr from hex aabbcc.dd to decimal ######.##
	RTS
.)

_HEX	.(		; HEX r			9r		Rr <- hex(Rr)	- convert Rr from decimal ######.## to hex aabbcc.dd
	RTS
.)

_GETPQ	.(		; sets X as p register and Y as q register, checks for overflow in the operands, advances PC
	LDY #0
	LDA (_PC),Y	; get source registers
	LSR
	LSR
	AND #_MSK_R	; p register
	TAX
	LDA (_PC),Y
	ASL
	ASL
	AND #_MSK_R	; q register
	TAY
	LDA _R0+3,X
	AND #_MSK_O	; check for existing overflow condition
	BEQ _1		; sign and overflow are both clear
	EOR #_MSK_O
	BEQ _1		; sign and overflow are both set
	BRK		; an operand is in an overflow condition, abort and call exception handler (TODO)
_1	LDA _R0+3,Y
	AND #_MSK_O	; check for existing overflow condition
	BEQ _2		; sign and overflow are both clear
	EOR #_MSK_O
	BEQ _2		; sign and overflow are both set
	BRK		; an operand is in an overflow condition, abort and call exception handler (TODO)
_2	INC _PCL	; advance PC
	BNE _3
	INC _PCH
_3	RTS
.)

_RETZD	.(		; clears register D, clears underflow, falls through to _TRFDR
	LDA #0
	STA _RD
	STA _RD+1
	STA _RD+2
	STA _RD+3
	LDA _F		; clear underflow
	AND #_F_U^$FF
	STA _F
.)

_TRFDR	.(		; pulls X, transfers RD to X as r register, updates overflow flag
	PLA
	TAX
	LDA _RD		; transfer result to Rr
	STA _R0,X
	LDA _RD+1
	STA _R0+1,X
	LDA _RD+2
	STA _R0+2,X
	LDA _RD+3
	STA _R0+3,X
	AND #_MSK_O	; check for overflow
	BEQ _4
	EOR #_MSK_O
	BEQ _4
_3	LDA _F		; set overflow
	ORA #_F_O
	STA _F
	BNE _5
_4	LDA _F		; clear overflow
	AND #_F_O^$FF
	STA _F
_5	RTS
.)

_ADD	.(		; ADD r pq		ar pq		Rr <- Rp + Rq	- addition
	TXA
	PHA		; save r register for later
	JSR _GETPQ
	CLC		; set RD to Rp + Rq
	LDA _R0,X
	ADC _R0,Y
	STA _RD		
	LDA _R0+1,X
	ADC _R0+1,Y
	STA _RD+1		
	LDA _R0+2,X
	ADC _R0+2,Y
	STA _RD+2		
	LDA _R0+3,X
	ADC _R0+3,Y
	STA _RD+3
	JMP _TRFDR	; pull X, transfer RD to r register, let it handle the return
.)

_SUB	.(		; SUB r pq		br pq		Rr <- Rp - Rq	- subtraction
	TXA
	PHA		; save r register for later
	JSR _GETPQ
	SEC		; set RD to Rp - Rq
	LDA _R0,X
	SBC _R0,Y
	STA _RD		
	LDA _R0+1,X
	SBC _R0+1,Y
	STA _RD+1		
	LDA _R0+2,X
	SBC _R0+2,Y
	STA _RD+2		
	LDA _R0+3,X
	SBC _R0+3,Y
	STA _RD+3
	JMP _TRFDR	; pull X, transfer RD to r register, let it handle the return
.)

_TRFQD	.(		; transfers Y as q register to RD
	LDA _R0,Y
	STA _RD
	LDA _R0+1,Y
	STA _RD+1
	LDA _R0+2,Y
	STA _RD+2
	LDA _R0+3,Y
	STA _RD+3
	RTS
.)

_NEGRY	.(		; negates register at Y
	SEC
	LDA #0
	SBC _R0,Y
	STA _R0,Y
	LDA #0
	SBC _R0+1,Y
	STA _R0+1,Y
	LDA #0
	SBC _R0+2,Y
	STA _R0+2,Y
	LDA #0
	SBC _R0+3,Y
	STA _R0+3,Y
	RTS
.)

_ABSRY	.(		; sets register at Y to absolute value
	LDA _R0+3,Y
	BMI _NEGRY
	RTS
.)

_MUL	.(		; MUL r pq		cr pq		Rr <- Rp * Rq	- multiplication
	TXA		; adapted from http://www.6502.org/source/integers/32muldiv.htm
	PHA		; save r register for later
	JSR _GETPQ
	LDA _R0,X	; check for zero argument
	ORA _R0+1,X
	ORA _R0+2,X
	ORA _R0+3,X
	BNE _1		; p is non-zero
	JMP _RETZD	; p is zero, return zero
_1	LDA _R0,Y	; check for zero argument
	ORA _R0+1,Y
	ORA _R0+2,Y
	ORA _R0+3,Y
	BNE _2		; q is non-zero
	JMP _RETZD	; q is zero, return zero
_2	LDA _R0+3,X	; save sign of register p
	AND #_MSK_O
	PHA
	EOR _R0+3,Y
	AND #_MSK_O	; save sign of product
	PHA
	JSR _TRFQD
	TXA
	TAY		; absolute value of register p
	JSR _ABSRY
	LDY #_RD-_R0	; absolute value of register q saved in D
	JSR _ABSRY
	LDA #0
	STA _RB+4	; clear upper half of product
	STA _RB+5
	STA _RB+6
	STA _RB+7
	LDY #34		; thirty bit multiply and four bit shift
_3	LSR _RD+3	; shift operand
	ROR _RD+2
	ROR _RD+1
	ROR _RD
	BCC _4		; skip adding in product if bit is zero
	CLC
	LDA _RB+4	; add in p register
	ADC _R0,X
	STA _RB+4
	LDA _RB+5
	ADC _R0+1,X
	STA _RB+5
	LDA _RB+6
	ADC _R0+2,X
	STA _RB+6
	LDA _RB+7
	ADC _R0+3,X
_4	ROR		; shift the product
	STA _RB+7
	ROR _RB+6
	ROR _RB+5
	ROR _RB+4
	ROR _RB+3
	ROR _RB+2
	ROR _RB+1
	ROR _RB
	DEY
	BNE _3		; repeat until bits are done
	LDA _RB+1	; copy result to RD
	STA _RD
	LDA _RB+2
	STA _RD+1
	LDA _RB+3
	STA _RD+2
	LDA _RB+4
	STA _RD+3
	AND #_MSK_O	; consider the overflow bits
	ORA _RB+5	; check all the other bytes
	ORA _RB+6
	ORA _RB+7
	BEQ _5		; all zeroes means no overflow
	LDA _RD+3	; overflow situation, set accordingly
	AND #_MSK_O^$FF	; set overflow
	ORA #_F_O
	STA _RD+3
	BNE _6
_5	LDA _RD		; check for underflow
	ORA _RD+1
	ORA _RD+2
	ORA _RD+3
	BNE _6		; non-zero result means no underflow
	LDA _F		; we checked earlier for zero operands, so a zero result means underflow, set underflow
	ORA #_F_U
	STA _F
	BNE _7
_6	LDA _F		; clear underflow
	AND #_F_U^$FF
	STA _F
_7	PLA		; set the sign of the product
	BEQ _8
	LDY #_RD-_R0	; negate register D
	JSR _NEGRY
_8	PLA		; reset the sign of register p
	BEQ _9
	TXA
	TAY
	JSR _NEGRY
_9	JMP _TRFDR	; pull X, transfer RD to r register, let it handle the return
.)

_CMPDC	.(		; compare D to C, return result in status
	LDA _RD+3
	CMP _RC+3
	BCC _1		; definitely less
	BNE _1		; definitely greater
	LDA _RD+2
	CMP _RC+2
	BCC _1		; definitely less
	BNE _1		; definitely greater
	LDA _RD+1
	CMP _RC+1
	BCC _1		; definitely less
	BNE _1		; definitely greater
	LDA _RD
	CMP _RC
_1	RTS
.)

_DIV	.(		; DIV r pq		dr pq		Rr <- Rp / Rq	- division
	TXA
	PHA		; save r register for later
	JSR _GETPQ
	LDA _R0,X	; check for zero argument
	ORA _R0+1,X
	ORA _R0+2,X
	ORA _R0+3,X
	BNE _1		; p is non-zero
	JMP _RETZD	; p is zero, return zero
_1	LDA _R0,Y	; check for zero argument
	ORA _R0+1,Y
	ORA _R0+2,Y
	ORA _R0+3,Y
	BNE _2		; q is non-zero
	BRK		; q is zero, abort and call exception handler (TODO)
_2	LDA _R0,X	; copy p to RD
	STA _RD
	LDA _R0+1,X
	STA _RD+1
	LDA _R0+2,X
	STA _RD+2
	LDA _R0+3,X
	STA _RD+3
	LDA _R0,Y	; copy q to RC
	STA _RC
	LDA _R0+1,Y
	STA _RC+1
	LDA _R0+2,Y
	STA _RC+2
	LDA _R0+3,Y
	STA _RC+3
	LDA #0		; set RB to 1
	STA _RB
	LDA #_PLS_1
	STA _RB+1
	LDA #0
	STA _RB+2
	STA _RB+3
	PLA		; restore r register
	TAX
	LDA #0		; set r to 0
	STA _R0,X
	STA _R0+1,X
	STA _R0+2,X
	STA _R0+3,X
	LDA _RD+3	; save sign of quotient
	EOR _RC+3
	AND #_MSK_O
	PHA
	LDY #_RD-_R0	; absolute value of register p saved in D
	JSR _ABSRY
	LDY #_RC-_R0	; absolute value of register q saved in C
	JSR _ABSRY
_3	JSR _CMPDC	; is D < C?
	BCC _4		; yes, continue
	BEQ _5		; D = C
	ASL _RC		; RC *= 2
	ROL _RC+1
	ROL _RC+2
	ROL _RC+3
	ASL _RB		; RB *= 2
	ROL _RB+1
	ROL _RB+2
	ROL _RB+3
	BCC _3
	; carry is set, means a real overflow condition
	LDA #$FF	; set to the maximum
	STA _R0,X
	STA _R0+1,X
	STA _R0+2,X
	LDA #_MAX_V|_F_O
	STA _R0+3,X
	JMP _9
_4	LDA _RB		; is RB > 0?
	ORA _RB+1
	ORA _RB+2
	ORA _RB+3
	BEQ _7		; no, done
	JSR _CMPDC	; is D >= C?
	BCC _6		; no, skip subtraction
_5	SEC		; RD -= RC
	LDA _RD
	SBC _RC
	STA _RD
	LDA _RD+1
	SBC _RC+1
	STA _RD+1
	LDA _RD+2
	SBC _RC+2
	STA _RD+2
	LDA _RD+3
	SBC _RC+3
	STA _RD+3
	CLC		; RX += RB
	LDA _R0,X
	ADC _RB
	STA _R0,X
	LDA _R0+1,X
	ADC _RB+1
	STA _R0+1,X
	LDA _R0+2,X
	ADC _RB+2
	STA _R0+2,X
	LDA _R0+3,X
	ADC _RB+3
	STA _R0+3,X
	LDA _RD		; is RD > 0?
	ORA _RD+1
	ORA _RD+2
	ORA _RD+3
	BEQ _7		; no, done
_6	CLC		; RC /= 2
	ROR _RC+3
	ROR _RC+2
	ROR _RC+1
	ROR _RC
	CLC		; RB /= 2
	ROR _RB+3
	ROR _RB+2
	ROR _RB+1
	ROR _RB
	JMP _4
_7	LDA _R0,X	; check for underflow
	ORA _R0+1,X
	ORA _R0+2,X
	ORA _R0+3,X
	BNE _8		; non-zero result means no underflow
	LDA _F		; we checked earlier for zero operands, so a zero result means underflow, set underflow
	ORA #_F_U
	STA _F
	BNE _A
_8	LDA _F		; clear underflow
	AND #_F_U^$FF
	STA _F
_9	LDA _R0+3,X	; check for overflow
	AND #_MSK_O
	BEQ _A		; all zero, no overflow
	LDA _F		; set overflow
	ORA #_F_O
	STA _F
	BNE _B
_A	LDA _F		; clear overflow
	AND #_F_O^$FF
	STA _F
_B	PLA		; set the sign of quotient
	BEQ _C
	TXA
	TAY
	JSR _NEGRY
_C	RTS
.)

_MOD	.(		; MOD r pq		er pq		Rr <- Rp % Rq	- modulus
	RTS
.)
	
_ESC	.(		; ESC			00				- escape back into regular assembler
	PLA		; discard the COMMON _1 return address
	PLA
	JSR _RES	; restore the registers
	JMP (_PC)	; get back in the code
.)

_RTN	.(		; RTN			01				- return from subroutine
	RTS
.)

_BRS	.(		; BRS xxyy		02 yy xx	PC <- PC + xxyy	- branch to subroutine
	RTS
.)

_BRA	.(		; BRA xxyy		03 yy xx	PC <- PC + xxyy	- branch always
	RTS
.)

_BRX	.(		; generic branch testing
	AND _F		; check the bit
	BNE _BRA	; if set, branch
	CLC		; not set, advance the program counter over the xxyy offset
	LDA #2
	ADC _PCL
	STA _PCL
	LDA #0
	ADC _PCH
	STA _PCH
	RTS
.)

_BRE	.(		; BRE xxyy		04 yy xx	PC <- PC + xxyy	- branch if Rp = Rq (after CMP)
	LDA #_F_E
	BNE _BRX
.)

_BRG	.(		; BRG xxyy		05 yy xx	PC <- PC + xxyy	- branch if Rp > Rq (after CMP)
	LDA #_F_G
	BNE _BRX
.)

_BRL	.(		; BRL xxyy		06 yy xx	PC <- PC + xxyy	- branch if Rp < Rq (after CMP)
	LDA #_F_L
	BNE _BRX
.)

_BRZ	.(		; BRZ xxyy		07 yy xx	PC <- PC + xxyy	- branch if Rr = 0.0 (after TST)
	LDA #_F_Z
	BNE _BRX
.)

_BRP	.(		; BRP xxyy		08 yy xx	PC <- PC + xxyy	- branch if Rr > 0.0 (after TST)
	LDA #_F_P
	BNE _BRX
.)

_BRN	.(		; BRN xxyy		09 yy xx	PC <- PC + xxyy	- branch if Rr < 0.0 (after TST)
	LDA #_F_N
	BNE _BRX
.)

_BRO	.(		; BRO xxyy		0a yy xx	PC <- PC + xxyy	- branch if overflow (after arithmetic operations)
	LDA #_F_O
	BNE _BRX
.)

_BRU	.(		; BRU xxyy		0b yy xx	PC <- PC + xxyy	- branch if underflow (after arithmetic operations)
	LDA #_F_U
	BNE _BRX
.)

_CPR	.(		; CPR pq		0c pq		Rp <- Rq	- copy register
	RTS
.)

_LDI	.(		; LDI pq		0d pq		Rp <- (Rq:bbcc)	- load indirect from memory
	RTS
.)

_SVI	.(		; SVI pq		0e pq		(Rp:bbcc) <- Rq	- save indirect to memory
	RTS
.)

_CMR	.(		; CMR pq		0f pq		F <- Rp <=> Rq	- compare registers
	RTS
.)

_END_CMN_CD

	; ROM data header
	.WORD CMN_DT, _END_CMN_DT - CMN_DT

	; beginning of ROM data
	* = CMN_DT

FN_0X	.WORD _ESC-1, _RTN-1, _BRS-1, _BRA-1, _BRE-1, _BRG-1, _BRL-1, _BRZ-1,
	.WORD _BRP-1, _BRN-1, _BRO-1, _BRU-1, _CPR-1, _LDI-1, _SVI-1, _CMR-1
FN_XR	.WORD _SET-1, _POP-1, _PSH-1, _EXC-1, _INR-1, _DCR-1, _TST-1,
	.WORD _DEC-1, _HEX-1, _ADD-1, _SUB-1, _MUL-1, _DIV-1, _MOD-1

_END_CMN_DT

	; 6502 addresses
	.WORD ADDR, 6

	; 6502 NMI, Reset and IRQ
	* = $FFFA
ADDR	.WORD 0, _INI, 0
