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
	LDY _RSI	; RS to I0
	LDA _RS-1,Y
	STA _I0+3
	LDA _RS-2,Y
	STA _I0+2
	LDA _RS-3,Y
	STA _I0+1
	LDA _RS-4,Y
	STA _I0
	LDA _R0,X	; copy Rr to RS
	STA _RS-4,Y
	LDA _R0+1,X
	STA _RS-3,Y
	LDA _R0+2,X
	STA _RS-2,Y
	LDA _R0+3,X
	STA _RS-1,Y
	LDA _I0		; copy I0 to Rr
	STA _R0,X
	LDA _I0+1
	STA _R0+1,X
	LDA _I0+2
	STA _R0+2,X
	LDA _I0+3
	STA _R0+3,X
	RTS
.)

_ADDI0X	.(		; add I0 to register indexed by X
	LDA _R0+3,X
	AND #_MSK_O	; check for existing overflow condition
	BEQ _1
	EOR #_MSK_O
	BNE _2		; existing overflow, skip decrement operation
_1	CLC		; adding RD
	LDA _I0
	ADC _R0,X
	STA _R0,X
	LDA _I0+1
	ADC _R0+1,X
	STA _R0+1,X
	LDA _I0+2
	ADC _R0+2,X
	STA _R0+2,X
	LDA _I0+3
	ADC _R0+3,X
	STA _R0+3,X
	AND #_MSK_O	; check for overflow
	BEQ _3
	EOR #_MSK_O
	BEQ _2
_2	LDA _F		; set overflow
	ORA #_F_O
	STA _F
	BNE _4
_3	LDA _F		; clear overflow
	AND #_F_O^$FF
	STA _F
_4	RTS
.)

_INR	.(		; INR r			5r		Rr <- Rr + 1.0	- increment register
	LDA #0		; set I0 to plus one
	STA _I0
	LDA #_PLS_1
	STA _I0+1
	LDA #0
	STA _I0+2
	STA _I0+3
	BEQ _ADDI0X
.)

_DCR	.(		; DCR r			6r		Rr <- Rr - 1.0	- decrement register
	LDA #0		; set I0 to minus one
	STA _I0
	LDA #_MNS_1
	STA _I0+1
	LDA #$FF
	STA _I0+2
	STA _I0+3
	BNE _ADDI0X
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

_ZERI0	.(		; clears I0
	LDA #0
	STA _I0
	STA _I0+1
	STA _I0+2
	STA _I0+3
	RTS
.)

_TRFI0X	.(		; transfer I0 to register indexed by X, MSB returned in A
	LDA _I0
	STA _R0,X
	LDA _I0+1
	STA _R0+1,X
	LDA _I0+2
	STA _R0+2,X
	LDA _I0+3
	STA _R0+3,X
	RTS
.)

_RTZI0X	.(		; clears I0, clears underflow, falls through to _RETI0X
	JSR _ZERI0
	LDA _F		; clear underflow
	AND #_F_U^$FF
	STA _F
.)

_RETI0X	.(		; pulls X, transfers I0 to register indexed by X, updates overflow flag
	PLA
	TAX
	JSR _TRFI0X	; transfer result to register indexed by X
	AND #_MSK_O	; check for overflow
	BEQ _1
	EOR #_MSK_O
	BEQ _1
	LDA _F		; set overflow
	ORA #_F_O
	STA _F
	BNE _2
_1	LDA _F		; clear overflow
	AND #_F_O^$FF
	STA _F
_2	RTS
.)

_ADD	.(		; ADD r pq		ar pq		Rr <- Rp + Rq	- addition
	TXA
	PHA		; save r register for later
	JSR _GETPQ
	CLC		; set I0 to Rp + Rq
	LDA _R0,X
	ADC _R0,Y
	STA _I0
	LDA _R0+1,X
	ADC _R0+1,Y
	STA _I0+1
	LDA _R0+2,X
	ADC _R0+2,Y
	STA _I0+2
	LDA _R0+3,X
	ADC _R0+3,Y
	STA _I0+3
	JMP _RETI0X	; pull X, transfer I0 to r register, let it handle the return
.)

_SUB	.(		; SUB r pq		br pq		Rr <- Rp - Rq	- subtraction
	TXA
	PHA		; save r register for later
	JSR _GETPQ
	SEC		; set I0 to Rp - Rq
	LDA _R0,X
	SBC _R0,Y
	STA _I0
	LDA _R0+1,X
	SBC _R0+1,Y
	STA _I0+1
	LDA _R0+2,X
	SBC _R0+2,Y
	STA _I0+2
	LDA _R0+3,X
	SBC _R0+3,Y
	STA _I0+3
	JMP _RETI0X	; pull X, transfer I0 to r register, let it handle the return
.)

_NEGX	.(		; negates register at X
	SEC
	LDA #0
	SBC _R0,X
	STA _R0,X
	LDA #0
	SBC _R0+1,X
	STA _R0+1,X
	LDA #0
	SBC _R0+2,X
	STA _R0+2,X
	LDA #0
	SBC _R0+3,X
	STA _R0+3,X
	RTS
.)

_ABSX	.(		; sets register at X to absolute value
	LDA _R0+3,X
	BMI _NEGX
	RTS
.)

_BKRRD	.(		; implement banker's rounding on quad-word pointed by X

	; The logic table below shows the expected results. The only differences are
	; when the least significant byte (LSB) is 128 and the second byte (2B) is even
	; vs odd.
	;
	; LSB	2B	CARRY	LSB + 127 + C	CARRY*	DELTA 2B*
	; <127	EVEN	0	<254		0	0
	; 127	EVEN	0	254		0	0
	; 128	EVEN	0	255		0	0 	<- not rounding up
	; 129	EVEN	0	0		1	+1
	; >129	EVEN	0	>0		1	+1
	; <127	ODD	1	<255		0	0
	; 127	ODD	1	255		0	0
	; 128	ODD	1	0		1	+1	<- rounding up
	; 129	ODD	1	1		1	+1
	; >129	ODD	1	>1		1	+1

	LDA _R0+1,X
	ROR		; will set carry if odd
	LDA _R0,X
	ADC #127	; adding just less than half
	STA _R0,X
	BCC _1
	INC _R0+1,X	; propagate through the rest
	BNE _1
	INC _R0+2,X
	BNE _1
	INC _R0+3,X
	BNE _1
	INC _R1,X
	BNE _1
	INC _R1+1,X
	BNE _1
	INC _R1+2,X
	BNE _1
	INC _R1+3,X
_1	RTS
.)

_CPXI0	.(		; copy four bytes at X index to I0, returns MSB in A
	LDA _R0,X
	STA _I0
	LDA _R0+1,X
	STA _I0+1
	LDA _R0+2,X
	STA _I0+2
	LDA _R0+3,X
	STA _I0+3
	RTS
.)

_RDXFI0	.(		; using X index, round quad-word, transfer to I0, set overflow in I0, set or clear the underflow flag
	JSR _BKRRD	; banker's rounding
	INX		; skip extra fraction
	JSR _CPXI0	; copy to I0
	AND #_MSK_O	; consider the overflow bits
	ORA _R1,X	; check all the other bytes
	ORA _R1+1,X
	ORA _R1+2,X
	BEQ _1		; all zeroes means no overflow
	LDA _I0+3	; overflow situation
	AND #_MSK_O^$FF	; set overflow
	ORA #_F_O
	STA _I0+3
_1	LDA _I0		; check for underflow
	ORA _I0+1
	ORA _I0+2
	ORA _I0+3
	BNE _2		; non-zero result means no underflow
	LDA _F		; we checked earlier for zero operands, so a zero result means underflow, set underflow
	ORA #_F_U
	STA _F
	BNE _3
_2	LDA _F		; clear underflow
	AND #_F_U^$FF
	STA _F
_3	RTS
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
	JMP _RTZI0X	; p is zero, return zero
_1	LDA _R0,Y	; check for zero argument
	ORA _R0+1,Y
	ORA _R0+2,Y
	ORA _R0+3,Y
	BNE _2		; q is non-zero
	JMP _RTZI0X	; q is zero, return zero
_2	LDA _R0+3,X
	EOR _R0+3,Y
	AND #_MSK_O	; save sign of product
	PHA
	JSR _CPXI0	; transfer p to I0
	LDA _R0,Y	; transfer q to I1
	STA _I1
	LDA _R0+1,Y
	STA _I1+1
	LDA _R0+2,Y
	STA _I1+2
	LDA _R0+3,Y
	STA _I1+3
	LDX #_I0-_R0
	JSR _ABSX	; set to absolute value
	LDX #_I1-_R0
	JSR _ABSX	; set to absolute value
	LDA #0
	STA _I3		; clear upper half of product in I3
	STA _I3+1
	STA _I3+2
	STA _I3+3
	LDY #34		; thirty bit multiply and four bit shift to ensure product is aligned
_3	LSR _I1+3	; get lowest bit of operand
	ROR _I1+2
	ROR _I1+1
	ROR _I1
	BCC _4		; skip adding in product if bit is zero
	CLC
	LDA _I3		; add in p register
	ADC _I0
	STA _I3
	LDA _I3+1
	ADC _I0+1
	STA _I3+1
	LDA _I3+2
	ADC _I0+2
	STA _I3+2
	LDA _I3+3
	ADC _I0+3
	STA _I3+3
_4	LSR _I3+3 	; shift the product down
	ROR _I3+2
	ROR _I3+1
	ROR _I3
	ROR _I2+3
	ROR _I2+2
	ROR _I2+1
	ROR _I2
	DEY
	BNE _3		; repeat until bits are done
	LDX #_I2-_R0
	JSR _RDXFI0	; round and transfer to I0, set or clear underflow flag
	PLA		; set the sign of the product
	BEQ _5
	LDX #_I0-_R0	; negate I0
	JSR _NEGX
_5	JMP _RETI0X	; pull X, transfer I0 to r register, let it handle the return
.)

_ZERQX	.(		; zero quad-word (64 bits) at X
	LDA #0
	STA _R0,X
	STA _R0+1,X
	STA _R0+2,X
	STA _R0+3,X
	STA _R0+4,X
	STA _R0+5,X
	STA _R0+6,X
	STA _R0+7,X
	RTS
.)

_INTDM	.(		; initialize for DIV and MOD, returns sign of result in A
	JSR _GETPQ
	LDA _R0,X	; check for zero argument
	ORA _R0+1,X
	ORA _R0+2,X
	ORA _R0+3,X
	BNE _1		; p is non-zero
	JMP _RTZI0X	; p is zero, return zero
_1	LDA _R0,Y	; check for zero argument
	ORA _R0+1,Y
	ORA _R0+2,Y
	ORA _R0+3,Y
	BNE _2		; q is non-zero
	BRK		; q is zero, abort and call exception handler (TODO)
	; I0 / I1 will form 64-bit quantity with high order bytes I1 as zero
_2	JSR _CPXI0	; copy p to I0
	LDX #_I1-_R0
	JSR _ZERQX
	; I2 / I3 will form 64-bit quantity with low order bytes I2 as zero
	LDA _R0,Y	; copy q to I3
	STA _I3
	LDA _R0+1,Y
	STA _I3+1
	LDA _R0+2,Y
	STA _I3+2
	LDA _R0+3,Y
	STA _I3+3
	; I4 / I5 will form 64-bit result
	LDX #_I4-_R0
	JSR _ZERQX
	LDA _I0+3	; get sign of result
	EOR _I3+3
	AND #_MSK_O
	RTS
.)

_CMPDM	.(		; compare I0/I1 to I2/I3, return result in status
	LDA _I1+3
	CMP _I3+3
	BCC _1		; definitely less
	BNE _1		; definitely greater
	LDA _I1+2
	CMP _I3+2
	BCC _1		; definitely less
	BNE _1		; definitely greater
	LDA _I1+1
	CMP _I3+1
	BCC _1		; definitely less
	BNE _1		; definitely greater
	LDA _I1
	CMP _I3
	BCC _1		; definitely less
	BNE _1		; definitely greater
	LDA _I0+3
	CMP _I2+3
	BCC _1		; definitely less
	BNE _1		; definitely greater
	LDA _I0+2
	CMP _I2+2
	BCC _1		; definitely less
	BNE _1		; definitely greater
	LDA _I0+1
	CMP _I2+1
	BCC _1		; definitely less
	BNE _1		; definitely greater
	LDA _I0
	CMP _I2
_1	RTS
.)

_UPDDM	.(		; update DIV and MOD
	SEC		; I0/I1 -= I2/I3
	LDA _I0
	SBC _I2
	STA _I0
	LDA _I0+1
	SBC _I2+1
	STA _I0+1
	LDA _I0+2
	SBC _I2+2
	STA _I0+2
	LDA _I0+3
	SBC _I2+3
	STA _I0+3
	LDA _I1
	SBC _I3
	STA _I1
	LDA _I1+1
	SBC _I3+1
	STA _I1+1
	LDA _I1+2
	SBC _I3+2
	STA _I1+2
	LDA _I1+3
	SBC _I3+3
	STA _I1+3
	RTS
.)

_SHUDM	.(		; shift up for DIV and MOD, C should be set or cleared as required
	ROL _I4		; I4/I5 *= 2
	ROL _I4+1
	ROL _I4+2
	ROL _I4+3
	ROL _I5
	ROL _I5+1
	ROL _I5+2
	ROL _I5+3
	RTS
.)

_SHDDM	.(		; shift down for DIV and MOD
	CLC		; I2/I3 /= 2
	ROR _I3+3
	ROR _I3+2
	ROR _I3+1
	ROR _I3
	ROR _I2+3
	ROR _I2+2
	ROR _I2+1
	ROR _I2
	RTS
.)

_DIV	.(		; DIV r pq		dr pq		Rr <- Rp / Rq	- division
	TXA
	PHA		; save r register for later
	JSR _INTDM	; initialize
	PHA		; save sign of result
	LDX #_I0-_R0	; absolute value of register p saved in I0
	JSR _ABSX
	LDX #_I3-_R0	; absolute value of register q saved in I3
	JSR _ABSX
	LDY #51		; 51 bits are enough, and ensure alignment
_1	JSR _CMPDM	; is I0/I1 < I2/I3
	BCC _2		; yes, skip subtraction
	BEQ _4		; special case when p = q
	JSR _UPDDM	; I0/I1 -= I2/I3
_2	JSR _SHUDM	; I4/I5 *= 2 += CARRY
	JSR _SHDDM	; I2/I3 /= 2
	DEY
	BNE _1
	BEQ _5
_3	CLC		; special case when p = q, just shift up to the end
_4	JSR _SHUDM	; I4/I5 *= 2 += CARRY
	DEY
	BNE _3
_5	LDX #_I4-_R0
	JSR _RDXFI0	; round and transfer to I0, set or clear underflow flag
	PLA		; set the sign of the product
	BEQ _6
	LDX #_I0-_R0	; negate I0
	JSR _NEGX
_6	JMP _RETI0X	; pull X, transfer I0 to r register, let it handle the return
.)

_MOD	.(
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
