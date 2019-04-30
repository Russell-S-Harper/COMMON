#include <stdint.h>
#include <stdio.h>
#include "emulator.h"

/* Register I6 maintains common status */
#define _R0	0xb0
#define _R8	0xd0
#define _I0	0xd8
#define _I6	0xf0
#define _I7	0xf4
#define _I8	0xf8

/* (dd cc bb aa) aa: index for register stack RS / ccbb: program counter PC / dd: flags F UONPZLGE */
#define _RSI	_I6		/* register stack index */
#define _PCL	_RSI + 1	/* program counter low */
#define _PCH	_PCL + 1	/* program counter high */
#define _F	_PCH + 1	/* flags */
#define _PC	_PCL		/* program counter */

/* register I7 maintains locations of code and allocated memory */
#define _CRL	_I7				/* code low and high bytes */
#define _CRH	_CRL + 1
#define _ARL	_CRH + 1			/* allocated low and high bytes */
#define _ARH	_ARL + 1
#define _CR	_CRL				/* code memory address */
#define _AR	_ARL				/* allocated memory address */

/* section modifiers */
#define _SM_FXD	0x01
#define _SM_RLC	0x02
#define _SM_CD	0x04
#define _SM_DT	0x08

/* section identifiers */
#define _RLC_CD	_SM_RLC + _SM_CD		/* relocatable code */
#define _RLC_DT	_SM_RLC + _SM_DT		/* relocatable data */

uint8_t memory[65536];

uint8_t read6502(uint16_t address) {
	return memory[address];
}

void write6502(uint16_t address, uint8_t value) {
	memory[address] = value;
}

void hook() {
	int i, j;

	printf("\n%04x %u %u\n", pc, instructions, clockticks6502);
	for (i = _R0; i < _R8; i += 4) {
		printf("R%d: ", (i - _R0) / 4);
		for (j = 0; j < 4; ++j)
			printf("%02x ", memory[i + j]);
		if (((i - _R0) / 4) % 4 == 3)
			printf("\n");
	}
	for (i = _I0; i < _I8; i += 4) {
		printf("I%d: ", (i - _I0) / 4);
		for (j = 0; j < 4; ++j)
			printf("%02x ", memory[i + j]);
		if (((i - _I0) / 4) % 4 == 3)
			printf("\n");
	}
}

int main() {

	uint8_t header[5];
	/* where to start relocatables */
	uint16_t index = 0x0600;

	while (fread(header, sizeof(header), 1, stdin))
	{
		uint8_t type = header[0];
		uint16_t entity = header[1] + (header[2] << 8);
		uint16_t length = header[3] + (header[4] << 8);

		printf("\n%x %04x %u\n", type, entity, length);

		switch (type) {
			case _SM_FXD: /* fixed code or data */
				/* entity is the address, length is the length of the code or data */
				fread(memory + entity, length, 1, stdin);
				break;

			case _RLC_CD: /* relocatable code */
				/* entity is the starting offset, length is the length of code */
				if (fread(memory + index, length, 1, stdin)) {
					/* offset the starting address */
					entity += index;
					/* save the starting address */
					memory[_CRL] = entity & 0xff;
					memory[_CRH] = entity >> 8;
					/* advance to the end of the section */
					index += length;
				}
				break;

			case _RLC_DT: /* relocatable data */
				/* entity is the length of zeroed data, length is the length of preset data */
				if (fread(memory + index, length, 1, stdin)) {
					/* save the start of the data */
					memory[_ARL] = index & 0xff;
					memory[_ARH] = index >> 8;
					/* advance to the end of the section */
					index += entity + length;
				}
				break;
		}
	}

	memory[_PCL] = 	memory[_CRL];
	memory[_PCH] = 	memory[_CRH];

	hookexternal(hook);

	reset6502();

	do
		step6502();
	while (memory[pc]);

	return 0;
}
