/**
* kmain.c
* Entry point of the kernel.
*/

#include "kernel.h"

void kmain(uint32_t boot_sig, uint32_t mb, uint32_t stack)	{
	vga_init(White, Black);
	
	/* Message to say that we made it here. */
	printf("In kernel, boot signature = 0x%X | MB @0x%X | Stack @0x%X\n",
		boot_sig, mb, stack);
}
