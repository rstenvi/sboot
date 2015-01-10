; boot.s
; Multiboot 1/2 compliant start of the kernel.
; Functionality
; - States that we are multiboot 1/2 compliant
; - Specify what information we need from the loader
; - Set up rest of environment
; - Jump to kernel in C


[BITS 32]

[GLOBAL start]

[EXTERN kmain]		; Kernel entry point

; Must be exported by link script
[EXTERN load_end]
[EXTERN bss_end]


[SECTION .text]

start:
	jmp rstart

; Can be 4-aligned on MB1, but no reason to change it
ALIGN 8
%include "inc/mb1.s"


ALIGN 4


rstart:
	; Initialize the stack
	mov esp, init_stack

	; Send it as parameter to kmain, so it knows where the stack is
	push esp

	; Push multiboot structure
	push ebx

	; This is the boot signature, which says if we where loaded from MB 1 or MB 2
	; or something else.
	push eax

	call kmain

	jmp $


; Temporary stack in the .bss segment
[SECTION .bss]
	resb 0x1000
	init_stack:
