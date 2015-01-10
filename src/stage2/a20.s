; a20.s
; Check the A20 gate and enable if possible.
; Heavily inspired by: http://wiki.osdev.org/A20_Line


[BITS 16]

; Some constants when interacting with the keyboard controller
%define IO_KEYBOARD_CTRL 0x60
%define IO_KEYBOARD_STAT 0x64


; Method that should be used to enable the A20 gate, this will try out all the
; different available methods. If this function fails, it should print an error
; and halt.
; Method used:
; - If NOT enabled: Try BIOS
; - If NOT enabled: Try Keyboard
; - If NOT enabled: Try A20 FAST
; - If NOT enabled: Return Failure
; Input: Nothing
; Output:
; - AX = 0 If unsuccessfull
; - AX = 1 if successfull
enable_a20:
	mov ax, 0
	call check_a20
	cmp ax, 1
	jz .success
	call enable_a20_bios
	call check_a20
	cmp ax, 1
	jz .success
	call enable_a20_keyboard
	call check_a20
	cmp ax, 1
	jz .success
.success:
	; EAX is already 0 or 1 at this point and we don't need to set it
	ret


; Check if A20 has been enabled.
check_a20:
	push ds
	push es
	push di
	push si

	xor ax, ax ; ax = 0
	mov es, ax

	not ax ; ax = 0xFFFF
	mov ds, ax

	mov di, 0x0600
	mov si, 0x0610

	mov al, byte [es:di]
	push ax

	mov al, byte [ds:si]
	push ax

	mov byte [es:di], 0x00
	mov byte [ds:si], 0xFF

	cmp byte [es:di], 0xFF

	pop ax
	mov byte [ds:si], al

	pop ax
	mov byte [es:di], al

	mov ax, 0
	je .exit

	mov ax, 1

.exit:
	pop si
	pop di
	pop es
	pop ds

	ret


; Try the BIOS to enable A20
; Input: Nothing
; Output:
; - AX = 0 If unsuccessfull
; - AX = 1 if successfull
enable_a20_bios:
	mov ax, 0x2401
	int 0x15
	ret

; Try the keyboard controller method to enable A20.
; Input: Nothing
; Output: Nothing
enable_a20_keyboard:
	call a20wait
	mov al, 0xAD
	out IO_KEYBOARD_STAT, al

	call a20wait
	mov al, 0xD0
	out IO_KEYBOARD_STAT, al

	call a20wait2
	in al, IO_KEYBOARD_CTRL
	push ax

	call a20wait
	mov al, 0xD1
	out IO_KEYBOARD_STAT, al

	call a20wait
	pop ax
	or al, 2
	out IO_KEYBOARD_CTRL, al

	call a20wait
	mov al, 0xAE
	out IO_KEYBOARD_STAT, al

	call a20wait
	ret


; Wait for response to the ready.
; Input:
; - BX = Which bit should be tested, 0 or 1
; Output: Nothing
a20wait:
	in al, IO_KEYBOARD_STAT
	test al, 2
	jnz a20wait
	ret
a20wait2:
	in al, IO_KEYBOARD_STAT
	test al, 1
	jz a20wait2
	ret


; Try the FAST method to enable A20
; Input: Nothing
; Output: Nothing
enable_a20_fast:
	in al, 0x92
	or al, 2
	out 0x92, al
	ret


