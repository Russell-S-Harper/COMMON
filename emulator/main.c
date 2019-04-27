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

#define CODE	0xaa				/* to indicate CODE section */
#define DATA	0x55				/* to indicate DATA section */

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

	while (fread(header, sizeof(header), 1, stdin))
	{
		uint8_t type = header[0];
		uint16_t index = header[1] + (header[2] << 8);
		uint16_t length = header[3] + (header[4] << 8);

		printf("\n%x %04x %u\n", type, index, length);

		if (fread(memory + index, length, 1, stdin))
		{
			switch (type) {
				case CODE:
					memory[_CRL] = 	header[1];
					memory[_CRH] = 	header[2];
					break;
				case DATA:
					memory[_ARL] = 	header[1];
					memory[_ARH] = 	header[2];
					break;
			}
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
