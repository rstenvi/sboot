; floppy.s
; Code to deal with disks.


%ifndef __FLOPPY_S
%define __FLOPPY_S


; Reset floppy disk
; Input:
; - DL = Drive number
; Output:
; Thrashes: NONE
disk_reset:
	pusha
	.reset:
		mov ah, 0
		int 0x13
		jc .reset	; Do until it succeeds
	popa
	ret


%endif
