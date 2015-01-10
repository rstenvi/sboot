; multiboot.s
; File for implementing the logic of multiboot 1 and 2.

[BITS 32]		; We should now be in 32-bit protected mode.


; Find the signature (MB_SIG) that says it is a multiboot 1 or 2 kernel.
; Input:
; - EBX = Start of kernel
; Output:
; - EAX = Offset from EBX to first byte in multiboot header
; - CF is set on failure, NOT set on success
find_mb_kernel:

	xor eax, eax	; Counter
	.loop:
		mov ecx, [ebx + eax]
		cmp ecx, MB_SIG
		; If we have found a match, result is already in eax
		je .match

		; Add and check next block
		add eax, MB_ALIGN
		cmp eax, MB_MAX
		jnz .loop
		; If we get here, it does not have a multiboot header
		stc
		ret
	.match:
		clc
		ret



; Check if we are able to load this kernel.
; This is for MB 1, for MB 2 we need to parse the Multiboot information request
; tag. That is a bit more work.
; Input:
; - EAX = Address to start of multiboot header
; Output
; - CF is set on failure, not set on success
mb_can_load:
	mov ebx, [eax+4]
	
	and ebx, MB_NOT_SUPPORTED
	cmp ebx, 0
	jnz .failure

	; Get the result back
	mov ebx, [eax+4]
	and ebx, MB_REQUIRED
	cmp ebx, MB_REQUIRED
	jnz .failure

	clc		; Success
	ret

	.failure:
		stc	; Error
		ret

; Move the image to the correct area in memory.
; NOTES:
; - It assumes none of the values are 0, this must be checked and maybe placed
;   beforehand
; Input:
; - ESI = Address to the start of the file
; - EBX = Offset from EDI to start of multiboot header
; Output:
; - CF flag is set on failure, cleared on success
; - EAX = Start of kernel space
; - EBX = End of kernel space
; - ESI = Pointer to signature (lower address space)
; THRASHES:
; - Pretty much everything
mb_move_executable:

	; Where signature is
	add esi, ebx
	push esi		; Need this when setting BSS segment
	mov ecx, [esi + 20]	; Where the kernel should end when placed

	mov edx, [esi + 12]	; Header addr
	mov eax, [esi + 16]	; Load addr

	sub edx, eax	; (header addr - load addr) in edx
	sub esi, edx	; Subtract result to get start of load

	sub ecx, eax	; Number of bytes in load segment
	
	mov edi, eax

	; ESI now contains a pointer to the area in memory that is the start of the
	; operating system code.
	; ECX contains the number of bytes in the load segment
	; EDI contains a pointer to the actual place in memory where the kernel
	; should be placed
	
	cld
	rep movsb
	
	pop esi	; Pointer to where signature is

	; Check that all the bytes have been copied
	cmp ecx, 0
	jnz .repfail
	
	
	; At last we initialize the BSS segment to 0
	

	; Get to the end of the load segment
	mov ecx, [esi + 24]	; Where BSS end

	.loop:
		mov dword [edi], 0
		add edi, 4
		cmp edi, ecx
		jl .loop


	; EAX already contains start of kernel
	; EBX will contain end of kernel
	; ESI already contains pointer to signature
	mov ebx, edi	; End of kernel

	clc
	ret
	.repfail:
		stc
		ret


