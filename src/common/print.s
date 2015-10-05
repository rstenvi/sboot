; print.s
; Code for printing data to the screen


%ifndef __PRINT_S
%define __PRINT_S

%include "vars.s"

; This can be excluded if we are running low on space
%if MINIMIZE = FALSE


; Print a string to the screen.
; Input:
; - SI = NULL terminated string
; THRASHES: AX
print_string:
	lodsb	; Load character into AL

	; If it is 0x00, we are done
	cmp al, 0
	jz .done
	mov ah, 0x0E
	int 0x10
	jmp print_string

.done:
	ret


%macro PRINT_HALT 1
	ferror_%1:
		mov si, %1
		call print_string
		cli
		hlt
%endmacro


%endif	; MINIMIZE

%endif
