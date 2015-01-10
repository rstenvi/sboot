OUTPUT_FORMAT("elf32-i386")
ENTRY(start)

SECTIONS
{
	/* 1 MB */
	. = 0x100000;
	
	.text : AT(ADDR(.text))
	{
		*(.text)
	}
	
	/*
	* We align all the others at the paging boundary
	*/

	.data ALIGN(4096) : AT(ADDR(.data))
	{
		*(.data)
		*(.rodata*)
	}
	load_end = .;

	.bss ALIGN(4096) : AT(ADDR(.bss))
	{
		*(COMMON*)
		*(.bss*)
	}
	bss_end = .;
}
