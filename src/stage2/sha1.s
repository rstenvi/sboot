; sha1.s
; Calculate SHA-1 hash of a region of memory.

%ifndef __SHA1_S
%define __SHA1_S

[BITS 32]



[GLOBAL sha1_init]
[GLOBAL sha1_update]
[GLOBAL sha1_complete]



%define H0 0x67452301
%define H1 0xEFCDAB89
%define H2 0x98BADCFE
%define H3 0x10325476
%define H4 0xC3D2E1F0


%define SHA1_K0  0x5a827999
%define SHA1_K20 0x6ed9eba1
%define SHA1_K40 0x8f1bbcdc
%define SHA1_K60 0xca62c1d6



%define CTX_OFFSET_INDEX 0
%define CTX_OFFSET_NUM_BLOCKS 4
%define CTX_OFFSET_HASH   8
	%define HASH_OFFSET_0 0
	%define HASH_OFFSET_1 4
	%define HASH_OFFSET_2 8
	%define HASH_OFFSET_3 12
	%define HASH_OFFSET_4 16
%define CTX_OFFSET_BLOCK  28


; PARAMS:
; - 1 = Index register
; - 2 = Constant to add
; - 3 = Base address register for context block
; - 4 = Output register (NOT EAX)
; THRASHES:
; - EAX (multiply)
%macro get_block_dword 4
	push %1
	add %1, %2
	and %1, 15
	mov eax, %1
	mov %4, 4
	mul %4
	mov %1, eax
	add %1, %3
	mov dword %4, [%1 + CTX_OFFSET_BLOCK]
	pop %1
%endmacro


; Initialize a block for hash calculation.
; INPUT:
; - ESI = Pointer to block that holds the calculations, must be X bytes large
sha1_init:
	mov dword [esi + CTX_OFFSET_INDEX], 0
	mov dword [esi + CTX_OFFSET_NUM_BLOCKS], 0

	mov dword [esi + CTX_OFFSET_HASH + HASH_OFFSET_0], H0
	mov dword [esi + CTX_OFFSET_HASH + HASH_OFFSET_1], H1
	mov dword [esi + CTX_OFFSET_HASH + HASH_OFFSET_2], H2
	mov dword [esi + CTX_OFFSET_HASH + HASH_OFFSET_3], H3
	mov dword [esi + CTX_OFFSET_HASH + HASH_OFFSET_4], H4
	
	clc
	ret



; Add new data to the hash.
; INPUT:
; - ESI = Pointer to context object
; - EDI = Pointer to byte stream that should be added
; - ECX = Length of byte stream in EDI
sha1_update:
	; Get current index count
	mov dword edx, [esi + CTX_OFFSET_INDEX]
	xor ebx, ebx	; Bytes in EDI processed
	.loop:
		cmp edx, 64
		jz .blockfull

		cmp ebx, ecx
		jz .bytesdone

		; Get next byte
		mov byte al, [edi + ebx]

		%if SHA1_BIG_ENDIAN = TRUE
			mov byte [esi + CTX_OFFSET_BLOCK + edx], al
		%else
			xor edx, 3
			mov byte [esi + CTX_OFFSET_BLOCK + edx], al
			xor edx, 3
		%endif

		inc edx
		inc ebx
		jmp .loop

	.blockfull:
		; Add total number of bytes
		mov eax, [esi + CTX_OFFSET_NUM_BLOCKS]
		inc eax
		mov [esi + CTX_OFFSET_NUM_BLOCKS], eax

		; ESI already contains context block
		call sha1_hash_block

		; We are back at index 0 and new block
		xor edx, edx
		jmp .loop
	
	.bytesdone:
		; Need to save which index we are at and then we are done
		mov dword [esi + CTX_OFFSET_INDEX], edx
		jmp .done

.done:
	clc
	ret


; Calculate the final hash.
; INPUT:
; - ESI = Pointer to context block
sha1_complete:
	mov dword eax, [esi + CTX_OFFSET_INDEX]
	mov ecx, eax

	%if SHA1_BIG_ENDIAN = FALSE
		xor eax, 3
		mov byte [eax + esi + CTX_OFFSET_BLOCK], 0x80
		xor eax, 3
	%else
		mov byte [eax + esi + CTX_OFFSET_BLOCK], 0x80
	%endif

	.loop:
		inc eax
		cmp eax, 64
		jge .donepadd

		%if SHA1_BIG_ENDIAN = FALSE
			xor eax, 3
		%endif

		mov byte [eax + esi + CTX_OFFSET_BLOCK], 0x00

		%if SHA1_BIG_ENDIAN = FALSE
			xor eax, 3
		%endif

		jmp .loop

.donepadd:
	cmp ecx, 55
	jg .process
	jmp .noprocess

.process:
	call sha1_hash_block

	xor ecx, ecx
	xor ebx, ebx
	.zeroloop:
		mov dword [esi + CTX_OFFSET_BLOCK + ecx], ebx
		add ecx, 4
		cmp ecx, 64
		jl .zeroloop

.noprocess:
	mov dword ebx, [esi + CTX_OFFSET_NUM_BLOCKS]
	shl ebx, 9
	mov dword ecx, [esi + CTX_OFFSET_INDEX]
	shl ecx, 3
	add ebx, ecx
	

	%if SHA1_BIG_ENDIAN = TRUE
		bswap ebx
	%endif

	mov dword [esi + CTX_OFFSET_BLOCK + 60], ebx
	call sha1_hash_block

	%if SHA1_BIG_ENDIAN = FALSE
		; Need to reverse the byte order on all the hashes
		mov dword eax, [esi + CTX_OFFSET_HASH + HASH_OFFSET_0]
		bswap eax
		mov dword [esi + CTX_OFFSET_HASH + HASH_OFFSET_0], eax

		mov dword eax, [esi + CTX_OFFSET_HASH + HASH_OFFSET_1]
		bswap eax
		mov dword [esi + CTX_OFFSET_HASH + HASH_OFFSET_1], eax
		
		mov dword eax, [esi + CTX_OFFSET_HASH + HASH_OFFSET_2]
		bswap eax
		mov dword [esi + CTX_OFFSET_HASH + HASH_OFFSET_2], eax
		
		mov dword eax, [esi + CTX_OFFSET_HASH + HASH_OFFSET_3]
		bswap eax
		mov dword [esi + CTX_OFFSET_HASH + HASH_OFFSET_3], eax
		
		mov dword eax, [esi + CTX_OFFSET_HASH + HASH_OFFSET_4]
		bswap eax
		mov dword [esi + CTX_OFFSET_HASH + HASH_OFFSET_4], eax
	%endif

	clc
	ret


; Do the actual hash calculation of a block.
; INPUT:
; - ESI = Context block
sha1_hash_block:
	pusha
	mov edi, esp	; Save where we stored the hash block
	sub edi, 4
	
	mov dword eax, [esi + CTX_OFFSET_HASH + HASH_OFFSET_0]
	push eax
	
	mov dword eax, [esi + CTX_OFFSET_HASH + HASH_OFFSET_1]
	push eax
	
	mov dword eax, [esi + CTX_OFFSET_HASH + HASH_OFFSET_2]
	push eax
	
	mov dword eax, [esi + CTX_OFFSET_HASH + HASH_OFFSET_3]
	push eax
	
	mov dword eax, [esi + CTX_OFFSET_HASH + HASH_OFFSET_4]
	push eax

	xor ecx, ecx
	.loop:
		push ecx
		cmp ecx, 16
		jge .ge16
		jmp .lt16
		.ge16:
			get_block_dword ecx, 13, esi, ebx
			get_block_dword ecx, 8, esi, edx
			xor ebx, edx
			get_block_dword ecx, 2, esi, edx
			xor ebx, edx
			get_block_dword ecx, 0, esi, edx
			xor ebx, edx

			rol ebx, 1
			mov eax, ecx
			and eax, 15
			mov edx, 4
			mul edx
			add eax, esi
			mov [eax + CTX_OFFSET_BLOCK], ebx

			
		.lt16:
		cmp ecx, 20
		jl .lt20
		
		cmp ecx, 40
		jl .lt40

		cmp ecx, 60
		jl .lt60

		jmp .ge60

		.lt20:
			;	([3] ^ ([1] & ([2] ^ [3]))) + SHA1_K0
			mov eax, [edi - HASH_OFFSET_2]
			mov ebx, [edi - HASH_OFFSET_3]
			xor eax, ebx
			mov ecx, [edi - HASH_OFFSET_1]
			and eax, ecx
			xor eax, ebx
			add eax, SHA1_K0
			jmp .endloop
		.lt40:
			; ([1] ^ [2] ^ [3]) + SHA1_K20
			mov eax, [edi - HASH_OFFSET_1]
			mov ebx, [edi - HASH_OFFSET_2]
			xor eax, ebx
			mov ebx, [edi - HASH_OFFSET_3]
			xor eax, ebx
			add eax, SHA1_K20
			jmp .endloop
		.lt60:
			; (([1] & [2]) | ([3] & ([1] | [2]))) + SHA1_K40
			mov eax, [edi - HASH_OFFSET_1]
			mov ebx, [edi - HASH_OFFSET_2]
			or eax, ebx
			mov edx, [edi - HASH_OFFSET_3]
			and eax, edx
			mov edx, [edi - HASH_OFFSET_1]
			mov ebx, [edi - HASH_OFFSET_2]
			and edx, ebx
			or eax, edx
			add eax, SHA1_K40
			jmp .endloop
		.ge60:
			; ([1] ^ [2] ^ [3]) + SHA1_K60
			mov eax, [edi - HASH_OFFSET_1]
			mov ebx, [edi - HASH_OFFSET_2]
			xor eax, ebx
			mov ebx, [edi - HASH_OFFSET_3]
			xor eax, ebx
			add eax, SHA1_K60
			jmp .endloop
			
		.endloop:
			mov ebx, [edi + HASH_OFFSET_0]
			rol ebx, 5
			add eax, ebx
			mov ebx, [edi - HASH_OFFSET_4]
			add eax, ebx
			pop ecx
			push ecx
			and ecx, 15
			push eax
			mov eax, ecx
			mov ecx, 4
			mul ecx
			mov ecx, eax
			pop eax
			mov dword ebx, [esi + CTX_OFFSET_BLOCK + ecx]
			add eax, ebx

			; Shift around the blocks a little
			mov dword ecx, [edi - HASH_OFFSET_3]
			mov dword [edi - HASH_OFFSET_4], ecx

			mov dword ecx, [edi - HASH_OFFSET_2]
			mov dword [edi - HASH_OFFSET_3], ecx

			mov dword ecx, [edi - HASH_OFFSET_1]
			rol ecx, 30
			mov dword [edi - HASH_OFFSET_2], ecx

			mov dword ecx, [edi - HASH_OFFSET_0]
			mov dword [edi - HASH_OFFSET_1], ecx

			; At last we place in the value we calculated this round
			mov dword [edi - HASH_OFFSET_0], eax

		pop ecx
		inc ecx
		cmp ecx, 80
		jl .loop

	; Save all the values in the context object
	mov ebx, [esi + CTX_OFFSET_HASH + HASH_OFFSET_0]
	mov ecx, [edi - HASH_OFFSET_0]
	add ebx, ecx
	mov [esi + CTX_OFFSET_HASH + HASH_OFFSET_0], ebx
	
	mov ebx, [esi + CTX_OFFSET_HASH + HASH_OFFSET_1]
	mov ecx, [edi - HASH_OFFSET_1]
	add ebx, ecx
	mov [esi + CTX_OFFSET_HASH + HASH_OFFSET_1], ebx
	
	mov ebx, [esi + CTX_OFFSET_HASH + HASH_OFFSET_2]
	mov ecx, [edi - HASH_OFFSET_2]
	add ebx, ecx
	mov [esi + CTX_OFFSET_HASH + HASH_OFFSET_2], ebx
	
	mov ebx, [esi + CTX_OFFSET_HASH + HASH_OFFSET_3]
	mov ecx, [edi - HASH_OFFSET_3]
	add ebx, ecx
	mov [esi + CTX_OFFSET_HASH + HASH_OFFSET_3], ebx
	
	mov ebx, [esi + CTX_OFFSET_HASH + HASH_OFFSET_4]
	mov ecx, [edi - HASH_OFFSET_4]
	add ebx, ecx
	mov [esi + CTX_OFFSET_HASH + HASH_OFFSET_4], ebx

	add esp, 20	; 5 pushes in the beginning

	popa
	clc
	ret


%endif
