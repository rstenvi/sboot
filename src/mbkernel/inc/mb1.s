; mb1.s
; Variables to define a multiboot 1 compliant OS.

; Magic value for MB 1
%define MAGIC 0x1BADB002

; Which features must be supported, the feature is NOT supported, the OS should
; NOT be loaded. Meaning of bits:
; - 0 - Align all modules on 4KB boundaries (pages)
; - 1 - Collect information about memory, should also be the memory map
; - 2 - Video mode table
; - 16 - loader should use information about executable from offset 12-28 in
;   this header, instead of the actual executable header. Compliant bootloaders
;   must be able to load executable files in ELF-format or has this bit and
;   information set.
;   - REMARK: Bootloader which is used here does NOT support loading of ELF-files,
;     so this information must always be provided.

%define FLAGS 0x00010003

%define MB_ENTRY start


MB_START:

magic:    dd MAGIC
flags:    dd FLAGS
checksum: dd CHECK


haddr:    dd MB_START
laddr:    dd start
leaddr:   dd load_end
beaddr:   dd bss_end
mbentry:  dd rstart

MB_END:

; Checksum, when CHECK, MAGIC, ARCH and HL is added together the result is 0
; (32-bit unsigned number)
CHECK equ -(MAGIC + FLAGS)
