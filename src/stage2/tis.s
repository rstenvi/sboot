
%ifndef __TIS_S
%define __TIS_S

[BITS 32]

%include "print_pmode.s"
%include "misc.s"


; Functions that can be called from the outside
[GLOBAL tis_init]
[GLOBAL tis_transmit]
[GLOBAL tis_get_access]

%define TIS_BASE_ADDR 0xfed40000


%define TPM_OFFSET_ACCESS 0x0
	%define TPM_BIT_ACCESS_VALID (1<<7)
	%define TPM_BIT_ACCESS_ACTIVE (1<<5)
	%define TPM_BIT_ACCESS_REQ_USE (1<<1)


%define TPM_OFFSET_STS 0x18
	%define TPM_BIT_STS_VALID      (1<<7)
	%define TPM_BIT_STS_CMD_READY  (1<<6)
	%define TPM_BIT_STS_GO         (1<<5)
	%define TPM_BIT_STS_DATA_AVAIL (1<<4)
	%define TPM_BIT_STS_EXPECT     (1<<3)
	%define TPM_BIT_STS_RETRY      (1<<2)

%define TPM_OFFSET_DATA_FIFO 0x24

%define TPM_DID_VID 0xf00



%define WAIT_TIMEOUT 1024





; Initialize the TPM
; OUTPUT:
; - EAX = Response from TPM
; - Carry flag set if TPM is not present, cleared if present and ready
tis_init:
	mov eax, [TIS_BASE_ADDR + TPM_DID_VID]
	bswap eax

	test eax, eax
	jz .failure
	cmp eax, 0xffffffff
	jz .failure

	clc
	ret

.failure:
	stc
	ret

; Send a command and recieve the response. This is the command that should be
; used.
; INPUT:
; - EAX = Length of command buffer
; - ESI = Address to command
; - ECX = Length of response buffer
; - EDI = Address to response buffer
; OUTPUT:
; - Carry flag is set on failure, cleared on success
; - EAX = Bytes written
; - ECX = Bytes read
; THRASHES:
; - Everything
tis_transmit:
	push ecx
	push esi
	mov ebx, esi
	; EAX already contains length
	call tis_write
	pop esi
	pop ecx
	jc .writefail


	push eax	; Save bytes written



	mov eax, ecx
	mov ebx, edi
	call tis_read
	mov ecx, eax
	pop eax
	jc .readfail


	clc
	ret
.writefail:
	; EAX already contains bytes written
	xor ecx, ecx	; 0 bytes read
	stc
	ret
.readfail:
	stc
	ret


; Send a given buffer to the TPM
; INPUT:
; - EBX = Address to the buffer
; - EAX = Length of the buffer
; OUTPUT
; - Carry flag is set on failure, cleared on success
; - EAX = Amount of data sent
tis_write:
	; Get the base address, included locality, in ECX
	xor ecx, ecx
	mov byte cl, [curr_local]
	shl ecx, 12
	add ecx, TIS_BASE_ADDR

	; Check if TPM is ready to receive
	mov byte dl,  [ecx + TPM_OFFSET_STS]
	and dl, TPM_BIT_STS_CMD_READY
	jnz .ready
	
	; Wake up the TPM
	mov byte [ecx + TPM_OFFSET_STS], TPM_BIT_STS_CMD_READY

	; Loop until it has woken up
	pusha
	mov eax, ecx
	xor ebx, ebx
	mov byte bl, TPM_BIT_STS_CMD_READY
	call int_wait_state
	popa
	jc .notready

.ready:
	; TPM is ready to receive
	; TODO: Check burst count and then check if it's valid

	xor esi, esi	; Counter for bytes sent
	.loop:
		mov byte dl, [ebx + esi]
		mov byte [ecx + TPM_OFFSET_DATA_FIFO], dl
		inc esi
		cmp esi, eax
		jnz .loop

	; All the data has been sent
	mov eax, esi	; Save amount of data sent

	; Check if the TPM expects more data
	mov byte dl, [ecx + TPM_OFFSET_STS]
	and dl, TPM_BIT_STS_EXPECT
	jnz .notenough

	; Execute the command
	mov byte [ecx + TPM_OFFSET_STS], TPM_BIT_STS_GO

	clc
	ret
.notready:
	xor eax, eax
.notenough:
	stc
	ret


; Read the result of a command
; INPUT:
; - EBX = Address to a buffer
; - EAX = Maximum length of buffer
; OUTPUT
; - EAX = Bytes read into address of EBX
; - Carry flag is set on failure, cleared on success
tis_read:
	xor ecx, ecx
	mov byte cl, [curr_local]
	shl ecx, 12
	add ecx, TIS_BASE_ADDR
	
	pusha
	mov eax, ecx
	mov bl, TPM_BIT_STS_VALID
	or bl, TPM_BIT_STS_DATA_AVAIL
	call int_wait_state
	popa
	jc .notvalid

	; Get data until there is no more data left
	xor esi, esi	; Bytes we have read
	.loop:
		; Check buffer length
		cmp esi, eax
		jge .notenoughspace

		; Check if more data is available
		mov byte dl, [ecx + TPM_OFFSET_STS]
		and dl, TPM_BIT_STS_DATA_AVAIL
		jz .done

		; Copy the data into the buffer
		mov byte dl, [ecx + TPM_OFFSET_DATA_FIFO]
		mov byte [ebx + esi], dl

		inc esi
		jmp .loop

		
.done:
	mov eax, esi
	clc
	ret

.notvalid:
	xor eax, eax
	stc
	ret
.notenoughspace:
	mov eax, esi
	stc
	ret

; Ask for access to a given locality.
; INPUT:
; - EAX = locality (0-4)
; OUTPUT
; - Carry flag set if we could not get access, cleared if we got access or had
;   access from before.
tis_get_access:
	push eax
	shl eax, 12
	add eax, TIS_BASE_ADDR

	; Check if access is valid
	mov byte bl, [eax + TPM_OFFSET_ACCESS]
	cmp bl, 0xff
	jz .accinvalid
	and bl, TPM_BIT_ACCESS_VALID
	jz .accinvalid

	; Check if we already have access
	mov byte bl, [eax + TPM_OFFSET_ACCESS]
	and bl, TPM_BIT_ACCESS_ACTIVE
	jnz .hasaccess


	; Try and get access
	mov byte [eax + TPM_OFFSET_ACCESS], TPM_BIT_ACCESS_REQ_USE

	push eax
	; Wait for 40 milliseconds
	mov eax, 400
	call sys_wait

	pop eax
	
	; Make the TPM ready to accept commands
	mov byte [eax + TPM_OFFSET_STS], TPM_BIT_STS_CMD_READY

	; Check if we have access
	mov byte bl, [eax + TPM_OFFSET_ACCESS]
	and bl, TPM_BIT_ACCESS_ACTIVE
	jz .failaccess

	; Save which locality we have access to
.hasaccess:
	pop eax
	mov byte [curr_local], al

	clc
	ret
.failaccess:
.accinvalid:
	pop eax
	stc
	ret

; Wait until a timeout value is reached or a state has changed to a given value.
; INPUT:
; - EAX = Base address
; - BL = state
int_wait_state:
	mov ecx, WAIT_TIMEOUT
	.loop:
		; Get the byte
		mov byte dl, [eax + TPM_OFFSET_STS]
		; Check if it has the given bits set
		and dl, bl
		cmp dl, bl
		jz .success

		; Wait a millisecond
		push eax
		mov eax, 1000
		call sys_wait
		pop eax

		; If we haven't reached our timeout value, we continue
		dec ecx
		jnz .loop

	; FAILURE
	stc
	ret
.success:
	clc
	ret



curr_local: db 0xff

%endif
