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

_INI .(			; initialize common
			; copy system functions (TODO)
			; load program (TODO)
	LDA #0		; clear RSI
	STA _RSI
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

_POP	.(		; POP r			2r		Rr <- RS	- pop from stack
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

_PSH	.(		; PSH r			3r		RS <- Rr	- push onto stack
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
	RTS
.)

_DEC	.(		; DEC r			8r		Rr <- dec(Rr)	- convert Rr from hex aabbcc.dd to decimal ######.##
	RTS
.)

_HEX	.(		; HEX r			9r		Rr <- hex(Rr)	- convert Rr from decimal ######.## to hex aabbcc.dd
	RTS
.)

_ADD	.(		; ADD r pq		ar pq		Rr <- Rp + Rq	- addition
	RTS
.)

_SUB	.(		; SUB r pq		br pq		Rr <- Rp - Rq	- subtraction
	RTS
.)

_MUL	.(		; MUL r pq		cr pq		Rr <- Rp * Rq	- multiplication
	RTS
.)

_DIV	.(		; DIV r pq		dr pq		Rr <- Rp / Rq	- division
	RTS
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




