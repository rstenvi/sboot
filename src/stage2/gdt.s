; gdt.s
; Code for setting up a temporary GDT so that we can enter protected mode.


%ifndef __GDT_S
%define __GDT_S


[BITS 16]

; Indexes for GDT structures
%define GDT_CODE 0x08
%define GDT_DATA 0x10


; Outside function to install the GDT
install_gdt:
	lgdt [gdt_ptr]
	ret



; The 3 entries in the GDT.
gdt_start:
	dd 0, 0	; Required null descriptor
	
	; Code (0x08)
	dw 0xffff
	dw 0x0000
	db 0x00
	db 10011010b
	db 11001111b
	db 0x00

	; Data (0x10)
	dw 0xffff
	dw 0x0000
	db 0x00
	db 10010010b
	db 11001111b
	db 0x00
gdt_end:

; Pointer that is actually loaded with lgdt
gdt_ptr:
	dw gdt_end - gdt_start - 1
	dd gdt_start


%endif
