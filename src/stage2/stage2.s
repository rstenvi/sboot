; stage2.s
; Main file for stage 2 of the bootloader.
; This does (in order):
; 1. Set up new memory segments and addresses
; 2. Enable A20 Gate
; 3. Install the GDT (NOT enabled yet)
; 4. Get memory map and place in our structure
; 5. Read in kernel in lower part of memory
; 6. Enter protected mode (enables GDT as well)
; 7. Move the kernel into higher memory
; 8. Jump to kernel entry point
; MISSING
; - Parse MB1 flags and fill in necessary information
;  - Only some information is sent
; - Boot and give info to MB2 kernel


[BITS 16]
%include "defs.s"
%include "mmap.s"

[ORG STAGE2_SEG * 16]

; First byte is the entry point, so we need to do a jump to main
jmp stage2


; Some messages
msg db 0x0a, 0x0d, "STAGE 2", 0x00
a20_fail db 0x0a, 0x0D, "Unable to enable A20 gate", 0x00
mb_fail db 0x0a, 0x0D, "Multiboot failure", 0x00


; Only MB 1 is supported
%if MB_VERSION = 1
	%include "mb1.s"
%elif MB_VERSION = 2
	jmp mb_failure
%else
	jmp mb_failure
%endif


%include "print.s"
%include "a20.s"
%include "gdt.s"
%include "memory.s"
%include "read.s"



; Real entry point
stage2:
	cli

	; Set up segment registers
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	mov ss, ax
	
	; Set up the stack, we use the same as stage 1
	mov ax, STAGE1_STACK
	mov sp, ax
	

	; Save boot device for kernel
	mov [mb_boot_dev], dl


	; Some debug info
	mov si, msg
	call print_string
	

	; Enable A20 gate, if we fail, we cannot go any further
	call enable_a20
	cmp ax, 1
	jnz failure_a20


	; Install the GDT
	call install_gdt

	; Get lower and higher memory and place that in the MB info structure
	call get_low_memory
	mov [mb_mem_lo], ax

	call get_high_memory
	mov [mb_mem_hi], ax


	; Get the complete memory map from the kernel, we place it as the end of the
	; stage 2.
	mov di, stage2_end
	call get_memory_map


	; Fill in more of the multiboot structure, where we can find the
	; memory map.
	mov WORD [mb_mmap_addr], stage2_end
	mov ax, 24
	mul bp
	mov [mb_mmap_len], bp



	; Read in the kernel
	mov ax, KERNEL_LOW_SEG
	mov es, ax
	mov ax, 5		; Stage 1 + stage 2 (TODO: Remove hardcode)
	
	mov bx, KERNEL_LOW_ADDR
	mov cx, KERNEL_SECTORS
	mov dl, [mb_boot_dev]
	call read_x_sectors




; We are now finished with everything we where supposed to do in real mode and
; can jump to protected mode with the GDT we created earlier.
enter_pmode:
	; Enable protected mode
	mov eax, cr0
	or eax, 1
	mov cr0, eax
	jmp 0x08:pmode



[BITS 32]

pmode:
	mov ax, 0x10	; GDT data segment
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov esp, 0x9000	; TODO: Remove hardcode
	
	; Check if the kernel is MB compliant
	mov ebx, KERNEL_LOW_ADDR
	call find_mb_kernel
	jc mb_failure

	push ebx		; Start of kernel
	push eax		; Offset to MB header

	; Check if we can load the kenel, we require flag 16 set and video NOT set
	add eax, ebx	; Memory value of MB header
	call mb_can_load
	jc mb_failure

	pop ebx		; Offset to MB header
	pop esi		; Start of kernel

	; Does NOT work, bad standard
	call mb_move_executable
	jc mb_failure

	push esi		; Start of OS MB header


	; TODO: Place Multiboot structure in a better place
	; EBX contains the end of the kernel, which is where we will place the
	; structure
	mov edi, ebx
	add edi, 0x10		; Some buffer
	push edi

	mov esi, mb_start
	mov ecx, mb_end
	sub ecx, mb_start


	cld
	rep movsb

	cmp ecx, 0
	jnz mb_failure

	pop ebx	; Stored EDI value (multiboot structure)


	; Final set up for loading kernel
	mov eax, MB_EAX	; MB signature

	pop esi	; Start of OS MB header

	; Entry point
	mov ecx, [esi + 28]

	jmp ecx
	
	cli
	hlt


mb_failure:
	mov si, mb_fail
	call print_string
	cli
	hlt



%include "multiboot.s"

ALIGN 8
stage2_end:
	; This is where we intend to store the memory map from BIOS

; 24 bytes (6 dwords) reserved for the memory map we get from BIOS.
bios_mm_addr: dd 0x0, 0x0, 0x0, 0x0, 0x0, 0x0

failure_a20:
	mov si, a20_fail
	call print_string
	cli
	hlt



; Not really needed, but it makes it easier to create the disk with dd
times 1536 - ($-$$) db 0

