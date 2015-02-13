; misc.s
; Various helper functions, to be used in protected mode.


%ifndef __MISC_S
%define __MISC_S

%include "print_pmode.s"


[BITS 32]

; Wait a given number of milliseconds.
; INPUT:
; - EAX = Number of milliseconds
; TODO: Use the PIT to wait the correct number of milliseconds
; - Should then also check the code in tis.s, which uses this code
sys_wait:
	mov ebx, 0x10
	mul ebx
	.loop:
		nop
		dec eax
		jnz .loop
	ret


; Print hash value from pcr.
; INPUT:
; - EDI = Pointer to 20 bytes that is the hash.
print_hash_pcr:
	xor ecx, ecx
	.loop:
		xor eax, eax
		push ecx
		push edi
		mov byte al, [edi + ecx]
		mov ebx, 16		; Base
		call screen_print_integer
		mov ebx, char_space
		call screen_print
		pop edi
		pop ecx
		inc ecx
		cmp cl, 20
		jl .loop
	mov ebx, char_newline
	call screen_print
	ret

%endif
