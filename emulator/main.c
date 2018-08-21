#include <stdint.h>
#include <stdio.h>
#include "emulator.h"

/* Register E maintains common status */
#define _RE	0xf8

/* (dd cc bb aa) aa: index for register stack RS / ccbb: program counter PC / dd: flags F UONPZLGE */
#define _RSI	_RE		/* register stack index */
#define _PCL	_RSI + 1	/* program counter low */
#define _PCH	_PCL + 1	/* program counter high */
#define _F	_PCH + 1	/* flags */
#define _PC	_PCL		/* program counter */

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
	for (i = 0x00b8; i < 0x00d8; i += 4) {
		printf("R%d: ", (i - 0x00b8) / 4);
		for (j = 0; j < 4; ++j)
			printf("%02x ", memory[i + j]);
		if (((i - 0x00b8) / 4) % 4 == 3)
			printf("\n");
	}
	for (i = 0x00e0; i < 0x0100; i += 4) {
		printf("I%d: ", (i - 0x00e0) / 4);
		for (j = 0; j < 4; ++j)
			printf("%02x ", memory[i + j]);
		if (((i - 0x00e0) / 4) % 4 == 3)
			printf("\n");
	}
}

int main() {

	uint8_t header[4];

	while (fread(header, sizeof(header), 1, stdin))
	{
		uint16_t index = header[0] + (header[1] << 8);
		uint16_t length = header[2] + (header[3] << 8);

		printf("\n%04x %u\n", index, length);

		if (fread(memory + index, length, 1, stdin))
		{
			memory[_PCL] = 	header[0];
			memory[_PCH] = 	header[1];
		}
	}

	hookexternal(hook);

	reset6502();

	do
		step6502();
	while (memory[pc]);

	return 0;
}
