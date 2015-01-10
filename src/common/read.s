; read.s
; Code for reading in real mode, this is used in stage 1 and stage 2.
; This should be able to read from any disk that is supported from the rest of
; the loader.
; External functions:
; - read_x_sectors (Read any number of sectors into memory.)
; - get_drive_geometry (floppy uses default values)


%ifndef __READ_S
%define __READ_S

%include "vars.s"
%include "floppy.s"

; A more general version of reading sectors, supports LBA addressing and it only
; reads 1 sector at a time to minimize the possibility of error.
; INPUT:
; - AX = LBA start address
; - ES:BX = Buffer that should be read to
; - CX = Number of sectors to read
; - DL = Drive number
; OUTPUT:
; - CF = SET on failure, unset on success
; THRASHES:
read_x_sectors:

	.loop:
		; Save all the registers we are going to thrash
		push cx
		push ax
		push bx
		push dx

		; AX already contains the start address
		call lba_to_chs2
		
		; Need to do some remapping from our result and to the next call
		; AX = Cylinder, CX = Sector, DX = Head
		mov ch, al	; Cylinder
		mov dh, ah	; Head
		; CL already contains sector
		; DH = head, CH = cylinder, CL = sector

		pop bx	; dx
		mov dl, bl	; Drive number

		xor ax, ax
	
		pop bx	; Address to write to

		call read_sectors_chs

		; If the carry flag is set, reading has failed
		jc .fail

		add bx, 512		; Next memory address

		; Next LBA address
		pop ax
		inc ax

		; Check counter if we have finished reading all the sectors
		pop cx
		dec cx
		jnz .loop

		; Ensure that we return a successfull value
		clc
		ret
.fail:
	; Some cleanup before we return
	pop ax
	pop cx
	ret
	


; Convert LBA address to CHS values.
; Algorithm:
; - A = LBA / sectors per track
; - Sector = LBA % sectors per track
; - Head = A % number of heads
; - Cylinder = A / number of heads
; Input:
; - AX = LBA address (NB! Starts at 0)
; Output:
; - AL = Cylinder
; - AH = Head
; - CL = Sector
; THRASHES:
lba_to_chs2:
	
	; div will store values in DX, so we need to store it as DL contains the
	; drive number.
	push dx
	push bx

	; Don't need to xor I think, check that, then we can also remove it below
	xor dx, dx
	xor bx, bx
	xor cx, cx

	mov cl, [sec_track]
	mov bl, [num_heads]

	div WORD cx		; AX / CX
	
	; Result in AX and quotient in DX, which means that DX holds sector and we
	; must store it.
	inc dx
	push dx	; DL = Sector


	xor dx, dx
	div WORD bx

	; Result in AX and quotient in DX
	mov ah, dl	; Head
	; AL contains the cylinder
	pop cx		; Sector

	; Not strictly necessary since only CL should be valid
	xor ch, ch

	; Pop back the drive value we saved
	pop bx
	pop dx
	ret


; Get the geometry of the drive
; NOTE: This does not work well when it is a floppy disk or emulated floppy
; disk, in those cases, a default value should be used.
; Input:
; - DL = Drive number
; Output:
; - CL = Sectors per track
; - BL = Number of heads
get_drive_geometry:
	push ax
	push dx
	mov ah, 0x08
	int 0x13

	and cl, 0x3F
	inc dh
	mov bl, dh

	pop dx
	pop ax
	ret
	

; Read 1 sector.
; Input:
; - CH = Cylinder
; - CL = Sector (PS: First sector is 1, NOT 0)

; - DH = Head
; - DL = Drive number

; - ES:BX = Buffer we should read to
; Output:
; - Buffer in ES:BX
; - Carry flag is set if we fail and cleared if we succeed
; Thrashes: AH, CL
; Rules for reading:
; - A read cannot cross a cylinder or head boundary
;  - The output of get_drive_geometry will say how much this is, since we are on
;    the first sector, it's sectors per track -1 after this
; - Cannot write past a 64KB boundary in memory
; Will try 5 times before jumping to FAILURE
; Parameters to int 0x13
; - AL = Number of sectors to read
; - AH = What kind of function we want (2 = read)
; - CL = Sector | (sector >> 2) & 0xC0
; - CH = Cylinder
; - DH = Head
; - DL = Drive number
read_sectors_chs:
	push di
	
	clc
	mov di, 0x0005
	.loop:
		mov ah, cl
		shr ah, 2
		and ah, 0xC0
		or cl, ah
		mov ah, 2
		mov al, 1
		int 0x13
		jnc .done

		; If we can't read we try to reset whatever disk we where reading from.
		call disk_reset

		; Decrement and jump back if we haven't reached our maximum limit
		dec di
		jnz .loop

		; We have reached our maximum limit and must mark failure
		stc
	.done:
		pop di
		ret



sec_track: db DEFAULT_NUM_TRACKS
num_heads: db DEFAULT_NUM_HEADS



%endif
