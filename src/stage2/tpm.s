; tpm.s
; Some basic TPM commands that can be executed.


[BITS 32]


%include "tis.s"

%define TPM_TAG_RQU_COMMAND 0x00C1


%define TPM_ORD_Extend  0x00000014
%define TPM_ORD_PcrRead 0x00000015


%define CMD_HEADER_SIZE 10

%define CMD_EXTEND_SIZE 34
%define CMD_PCRREAD_SIZE 14

%define PCRREAD_OUTPUT_SIZE 30
%define EXTEND_OUTPUT_SIZE 30





%macro set_word 3
	mov ax, %1
	mov byte [%2 + %3], ah
	mov byte [%2 + %3+1], al
%endmacro

%macro set_dword 3
	mov eax, %1
	bswap eax
	mov dword [%2 + %3], eax
%endmacro


%macro copy_result 2
	mov esi, %1 + CMD_HEADER_SIZE
	mov ecx, (%2 - CMD_HEADER_SIZE)
	cld
	rep movsb
%endmacro




%define TEMP_CMD_BUFFER_SZ 128

tmp_send_buffer:
	resb TEMP_CMD_BUFFER_SZ
tmp_send_buffer_end:

%define TEMP_CMD_BUFFER_OUT_SZ 128

tmp_resp_buffer:
	resb TEMP_CMD_BUFFER_OUT_SZ
tmp_resp_buffer_end:



; Read the value of a PCR
; INPUT:
; - EAX = PCR index
; - EDI = Response buffer (everything after header)
; OUTPUT:
; - Carry flag is set on failure, cleared on success
; - EAX = result from TPM
TPM_PCRRead:
	push eax
	set_word TPM_TAG_RQU_COMMAND, tmp_send_buffer, 0
	set_dword CMD_PCRREAD_SIZE, tmp_send_buffer, 2
	set_dword TPM_ORD_PcrRead, tmp_send_buffer, 6
	pop eax
	set_dword eax, tmp_send_buffer, 10	; PCR index

	push edi

	; All the data has been set
	mov eax, CMD_PCRREAD_SIZE,
	mov esi, tmp_send_buffer,

	mov ecx, TEMP_CMD_BUFFER_OUT_SZ
	mov edi, tmp_resp_buffer

	call tis_transmit
	jc .failure


	mov dword eax, [tmp_resp_buffer + 6]
	bswap eax
	test eax, eax
	jnz .failure
	
	pop edi
	copy_result tmp_resp_buffer, PCRREAD_OUTPUT_SIZE
	test ecx, ecx
	jnz .failure2

	clc
	ret

.failure:
	pop edi
.failure2:
	stc
	ret


; Extend a PCR register with a given hash value.
; INPUT:
; - EAX = PCR index
; - EDI = Response buffer (everything after header)
; - ESI = 20-byte hash value
; OUTPUT:
; - Carry flag is set on failure, cleared on success
; - EAX = result from TPM
TPM_Extend:
	push eax
	set_word TPM_TAG_RQU_COMMAND, tmp_send_buffer, 0
	set_dword CMD_EXTEND_SIZE, tmp_send_buffer, 2
	set_dword TPM_ORD_Extend, tmp_send_buffer, 6
	pop eax
	set_dword eax, tmp_send_buffer, 10	; PCR index

	push edi

	; ESI contains hash
	mov edi, tmp_send_buffer + 14
	mov ecx, 20
	cld
	rep movsb

	test ecx, ecx
	jnz .failure

	; All the data is now set

	; Set the registers
	mov eax, CMD_EXTEND_SIZE
	mov esi, tmp_send_buffer

	mov ecx, TEMP_CMD_BUFFER_OUT_SZ
	mov edi, tmp_resp_buffer

	call tis_transmit
	jc .failure

	; Get the TPM result code, 0 means success, everything else is failure
	mov dword eax, [tmp_resp_buffer + 6]
	bswap eax
	test eax, eax
	jnz .failure

	; Get the response after the header and write it back

	pop edi	; Pop back response buffer for caller
	copy_result tmp_resp_buffer, EXTEND_OUTPUT_SIZE
	test ecx, ecx
	jnz .failure2

	clc
	ret

.failure:
	pop edi	; Keep the stack in order
.failure2:
	stc
	ret
	

