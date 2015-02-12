; print_pmode.s
; Print to screen in protected mode

%ifndef __PRINT_PMODE_S
%define __PRINT_PMODE_S



[BITS 32]

%define SCREEN_ADDR 0xb8000
%define SCREEN_LENGTH 80
%define SCREEN_HEIGHT 25
%define COLOR_FG 0xf
%define COLOR_BG 0x0
%define BLANK 0x20
%define COLOR (COLOR_BG << 4) + COLOR_FG
%define BLANK_WORD (COLOR << 8) + BLANK

%define CHAR_NEWLINE 0x0A
%define CHAR_TAB     0x09

; Store where we are on the screen
x_location: db 0x00
y_location: db 0x00

; Used to support multiple bases
numalph: db "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

; 12 bytes to handle converting integers to strings
%define TEMP_BUFFER_SZ 12

temp_print_buffer:
	resb TEMP_BUFFER_SZ
temp_print_buffer_end:


; Code to clear the buffer used when converting integers to string
; Must be done every time after use and on initialization
screen_clear_temp:
	; Need to zero out buffer we 
	mov edx, TEMP_BUFFER_SZ-1
	mov ecx, temp_print_buffer
	.loop2:
		mov byte [ecx+edx], 0x00
		dec edx
		jnz .loop2

	ret
	

screen_init:
	; Memory address for display is linear:
	; - SCREEN_HEIGHT * SCREEN_LENGTH words
	mov ebx, SCREEN_HEIGHT
	mov eax, SCREEN_LENGTH
	mul dword ebx	; SCREEN_LENGTH * SCREEN_HEIGHT
	mov ebx, 2
	mul dword ebx	; One word is 2 bytes

	; Set it all to be blank
	mov ecx, SCREEN_ADDR
	xor edx, edx
	.loop:
		mov word [ecx+edx], BLANK_WORD
		add edx, 2
		cmp edx, eax
		jnz .loop

	; Clear the buffer used when converting integers to strings
	call screen_clear_temp

	ret

; INPUT:
; - EBX = Pointer to null terminated string
screen_print:
	; AH is the top byte that says color
	mov byte ah, COLOR


	; Get current location
	mov byte dl, [x_location]
	mov byte dh, [y_location]
	.loop:
		; Get byte and check if it's zero
		mov byte al, [ebx]
		cmp al, 0x00
		jz .done

		; Check if it's a newline
		cmp byte al, CHAR_NEWLINE
		jz .printnewline

		cmp byte al, CHAR_TAB
		jz .printtab

		jmp .loopagain

		.printnewline:
			inc dh
			mov dl, 0x00
			jmp .loopagainprinted

		.printtab:
			add dl, 4
			and dl, 0b11111100
			jmp .loopagainprinted

		.loopagain:
			; Check if we should go on a new line
			inc dl
			cmp dl, SCREEN_LENGTH
			jge .newline
			jmp .nochange

			.newline:
			inc dh
			mov dl, 0x00

			.nochange:
			; TODO: Should check if we should scroll here

			push eax	; Save word we should print
			
			; Get what we should add to the screen address
			xor ecx, ecx
			mov cl, dl		; Get X value in ECX

			; Get number of lines in EAX
			xor eax, eax
			mov al, dh
			
			push edx

			; Multiply number of lines with screen length
			mov edx, SCREEN_LENGTH
			mul edx

			
			; Add X value
			add eax, ecx

			; Multiply by 2 since we are dealing with words
			mov ecx, 2
			mul ecx

			pop edx
			; Move result over in ecx and pop back word to print
			mov ecx, eax
			pop eax
			
			; Print the word
			mov word [SCREEN_ADDR+ecx], ax

			.loopagainprinted:

			; Get next byte and back to loop
			inc ebx
			jmp .loop

.done:
	; Store where we are for next print
	mov byte [x_location], dl
	mov byte [y_location], dh
	ret


; Print a number to the screen
; INPUT:
; - EAX = Number
; - EBX = base
screen_print_integer:
	; Need to treat 0 as a special case
	test eax, eax
	jnz .nozerocase
	mov ebx, temp_print_buffer
	mov byte [ebx], 0x30
	call screen_print
	ret

.nozerocase:
	mov ecx, eax 
	mov eax, 1
	xor edx, edx
	.loophigh:
		cmp eax, ecx
		ja .loopdone
		mul ebx
		test edx, edx
		jnz .overflow

		jmp .loophigh

.loopdone:
	; We have gone one to far and must divide by the base
	div ebx
	jmp .next

.overflow:
	; On overflow we fail
	ret

.next:
	xchg eax, ecx	; Get number to print back in eax
	mov esi, ecx	; Get Number to divide by in esi
	xor edi, edi

	; EAX = number to print
	; EBX = base
	; ECX = free
	; ESI = Current number we are dividing on
	; EDI = Counter for character array
	; EDX = Continually trashed by div
	.loopagain:
		push eax
		div esi		; Remainder in eax and quotient in edx
		mov byte cl, [numalph + eax]
		mov byte [temp_print_buffer+edi], cl
		inc edi

		; Need to subtract divide number * number saved from number to print
		mul esi
		mov ecx, eax
		pop eax			; Pop back whole number to print
		sub eax, ecx	; Subtract the value

		; esi should be divided by the base (ebx)

		; Save EAX again and divide the dividend by the base
		; save the remainder back in ESI
		push eax
		mov eax, esi
		div ebx
		mov esi, eax
		pop eax

		cmp esi, 0
		jz .donecalc
		jmp .loopagain

.donecalc:
	; Ready to print
	mov ebx, temp_print_buffer
	call screen_print

	; Need to clear the memory region again
	call screen_clear_temp
	ret


%endif
