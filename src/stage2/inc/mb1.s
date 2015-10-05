; mb1.s
; All the values that are passed to the kernel in Multiboot 1.

%ifndef __MB_STRUCT_S
%define __MB_STRUCT_S


[BITS 16]

mb_start:
mb_flags:       dd 0
mb_mem_lo:      dd 0
mb_mem_hi:      dd 0
mb_boot_dev:    dd 0
mb_boot_cmd:    dd 0
mb_mod_count:   dd 0
mb_mod_addr:    dd 0
mb_syms0:       dd 0
mb_syms1:       dd 0
mb_syms2:       dd 0
mb_syms3:       dd 0
mb_mmap_len:    dd 0
mb_mmap_addr:   dd 0
mb_drv_len:     dd 0
mb_drv_addr:    dd 0
mb_conf_tab:    dd 0
mb_bootl_name:  dd 0
mb_apm_tab:     dd 0
mb_vbe_ctrl:    dd 0
mb_vbe_mode:    dw 0
mb_vbe_int_seg: dw 0
mb_vbe_int_off: dw 0
mb_vbe_int_len: dw 0

mb_end:

%endif
