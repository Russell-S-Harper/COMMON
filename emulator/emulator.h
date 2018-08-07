#ifndef __EMULATOR_H
#define __EMULATOR_H

#include <stdint.h>

/* Accessing memory */
extern uint8_t read6502(uint16_t address);
extern void write6502(uint16_t address, uint8_t value);

/* Call this once before you begin execution. */
void reset6502();

/* Execute 6502 code up to the next specified count of clock ticks. */
void exec6502(uint32_t tickcount);

/* Execute a single instrution. */
void step6502();

/* Trigger a hardware IRQ in the 6502 core. */
void irq6502();

/* Trigger an NMI in the 6502 core. */
void nmi6502();

/* Pass a pointer to a void function taking no parameters. This will
   cause Fake6502 to call that function once after each emulated
   instruction. */
void hookexternal(void *funcptr);

/* Useful variables in this emulator */

/* Running total of the emulated cycle count. */
extern uint32_t clockticks6502;

/* Running total of the total emulated instruction count. This is not
   related to clock cycle timing. */
extern uint32_t instructions;

/* When this is defined, undocumented opcodes are handled otherwise,
   they're simply treated as NOPs. */
#define UNDOCUMENTED

/* When this is defined, the binary-coded decimal (BCD) status flag
   is not honored by ADC and SBC. The 2A03 CPU in the Nintendo
   Entertainment System does not support BCD operation. */
#undef NES_CPU

/* 6502 CPU registers */
extern uint16_t pc;
extern uint8_t sp, a, x, y, status;

#endif /* __EMULATOR_H */
