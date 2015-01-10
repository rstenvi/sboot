; Stage1.s
; Main code file for the stage 1 bootloader.
; Purpose: Load stage 2 into memory and jump to it.
; Stage 2 must then also be a binary file where the first byte contains the code

; Steps for all:
; - Disable interrupts
; - Set segment registers in predictable state
; - Create the stack
; - Enable interrupts

; Steps for floppy:
; - Reset floppy controller
; - Read number of sectors need to place stage 2 in memory

; Last step:
; - Jump to stage 2 code

[ORG 0x0000]
[BITS 16]			; Currently in 16 bit mdoe


start:
	jmp load


%include "vars.s"
%include "mmap.s"
%include "read.s"
%include "floppy.s"
%include "print.s"

; Entry point
load:
	cli			; Disable interrupts

	; Set up all the registers to point to this segment
	mov ax, STAGE1_SEG
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	
	; Create a stack
	xor ax, ax
	mov ss, ax
	mov sp, STACK_START
	
	; Save the device we have been booted from
	mov [boot_dev], dl

	sti		; Enable interrupts


%if DRIVE = DEV_FLOPPY
	call disk_reset
%else
	call get_drive_geometry
	mov [sec_track], cl
	mov [num_heads], bl
%endif


%if MINIMIZE = FALSE
	; Clear the screen
	mov ax, 0x0003
	int 0x10
%endif


%if FS = FS_NONE
	; Place stage 2 segment in ES
	mov ax, STAGE2_SEG
	mov es, ax

	mov ax, 1
	mov bx, STAGE2_ADDR		; The address stage two should be loaded at
	mov cx, STAGE2_SECTORS	; Number of sectors that stage 2 occupy

	call read_x_sectors
	jc FAILURE


%elif FS = FS_EXT2
	; Not supported yet
	jc FAILURE
%else
	; Undefined FS, should fail
	jc FAILURE
%endif


; Print welcome message if we are not conserving space
%if MINIMIZE = FALSE
	mov si, bootmsg
	call print_string
%endif


	; Should pass the drive number to stage 2
	mov dl, [boot_dev]
	
	; Push the new segment and address and jump to the new location while
	; updating CS
	push STAGE2_SEG
	push STAGE2_ADDR
	retf


; Notify of failure and wait for keypress, then do a soft reboot
FAILURE:
	%if MINIMIZE = FALSE
		mov si, msg_failure
		call print_string
	%endif
	cli
	hlt


; BIOS passes us the number for the device we are currently booted from, we
; should save this here so the DX register can be used freely.
boot_dev db 0



%if MINIMIZE = FALSE
	; Message that is printed on failure, not very descriptive, but not a lot of
	; space either.
	msg_failure: db "FAILURE", 0x00
	bootmsg db "BOOTING", 0x00
%endif


; Must be 512 bytes in size
times 510 - ($-$$) db 0


; Boot signature
dw 0xAA55

