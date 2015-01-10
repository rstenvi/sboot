; mb2.s
; A start on the values we need to pass to a MB2 kernel (NOT finished).

%ifndef __MB_STRUCT_S
%define __MB_STRUCT_S

[BITS 16]

mb_start:

; Fixed part
mb_tot_sz:      dd 0
mb_zero:        dd 0

; Series of tags, this should be more dynamic

; Memory tag
mb_type_mem     dd 4
mb_size_mem     dd 16
mb_mem_lo:      dd 0
mb_mem_hi:      dd 0

; BIOS boot device
mb_type_boot     dd 5
mb_size_boot     dd 20
mb_boot_dev:     dd 0
mb_boot_part:    dd 0
mb_boot_subpart: dd 0

mb_end:

%endif
