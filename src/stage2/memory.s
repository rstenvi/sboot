; memory.s
; Various functions to get memory from BIOS
; Several methods:
; - http://wiki.osdev.org/Detecting_Memory_(x86)

[BITS 16]

; Get the amount of low memory.
; Input: None
; Output:
; - AX = Number of KB in low memory or 0 if failure
get_low_memory:
	; AX will either contain the amount of KB in low memory or it will an error.
	; If it fails the carry flag is set
	xor ax, ax
	int 0x12
	jc .lowerror

	test ax, ax
	jz .lowerror
	ret

.lowerror:
	mov ax, 0
	ret


; Get the amount of higher memory, in KB.
; Input: Nothing
; Output:
; - AX = KB of memory above 1MB
get_high_memory:
	mov ax, 0x88
	int 0x15
	; Overflow flag is set if it failed
	jc .hierror

	; Check if it's 0
	test ax, ax
	jz .hierror

	; Unsupported function
	cmp ah, 0x86
	jz .hierror

	; Invalid command
	cmp ah, 0x80
	jz .hierror
	ret

.hierror:
	mov ax, 0
	ret




; Get a complete memory map from the BIOS, using int 0x15 with AX = 0xE820
; Based on: http://wiki.osdev.org/Detecting_Memory_%28x86%29#Getting_an_E820_Memory_Map

; Input:
; - ES:DI = Destination buffer
; Output
; - BP = Number of 24B entries
; About the entries:
; - B0-7: Base address.
; - B8-15: Length
; - B16-19: Type:
;  - 1: Usable and free RAM
;  - 2: Reserved - Unusable
;  - 3: ACPI - can be reclaimed
;  - 4: ACPI NVS memory
;  - 5: Bad memory
; - 20:23: ACPI 3.0 extended attribute field, can be:
;  - Bit 0: If set: this entry should be ignored
;  - Bit 1: If set: Might not be usable as RAM?
;  - Bit 2:31: Undefined
; This function will skip entries where Bit 0 in (20:23) is set, so the caller
; must just transform them into how they are specified to be in the multiboot
; specification, both use 24B entries. It would also be nice to sort the list
; based on addresses, but that is not a requirement, as far as I can see.
; In MB 1:
; - Size of the entry must be placed before the first 20 bytes. The last 4 bytes
;   is not used. A trick here is to reserve four bytes at the beginning, before
;   calling this function, then you can use the first 4 bytes as size for the
;   first entry and transform remaining ACPI fields as size for the other
;   entries. Last 4 bytes in the entire block is then unused.
; In MB 2:
; -  The entry can be used directly, although the the last 4 B are reserved and
;    should contain 0. This can also be used to set ACPI 3.0 information.
get_memory_map:
	xor ebx, ebx
	xor bp, bp
	mov edx, 0x0534D4150
	mov eax, 0xE820

	; Is set to 1 to be a valid ACPI entry
	mov [es:di + 20], DWORD 1
	mov ecx, 24		; 24 bytes
	int 0x15

	; Overflow flag is set if there was an error
	jc .failed

	; BIOS might thrash this register
	mov edx, 0x0534D4150
	
	; EAX should contain 0x0534D4150 on success
	cmp eax, edx
	jne .failed

	; If EBX is 0, then there is only 1 entry, which is useless
	test ebx, ebx
	je .failed

	jmp .start
.next:
	; This is thrashed by the BIOS  every time
	mov eax, 0xE820
	mov [es:di + 20], DWORD 1
	mov ecx, 24
	int 0x15
	jc .done

.start:
	; If the entry has length 0, we skip it
	jcxz .skipentry
	cmp cl, 20
	jbe .notext
	test BYTE [es:edi + 20], 1
	je .skipentry

.notext:
	mov ecx, [es:di + 8]
	or ecx, [es:di + 12]
	jz .skipentry
	inc bp
	add di, 24

.skipentry:
	test ebx, ebx
	jne .next

.failed:
	stc
	ret

.done:
	ret



