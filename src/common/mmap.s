; mmap.s
; This file explains the layout of the first 1 MB of memory. This is then a
; description of where things are when in real mode. When the word kernel is
; used, what I really mean is the stage after 2 when we are in protected mode.
; It can be a kernel or it can be another intermediary stage.

; The memory map is typically like this:
; 0x000000 -> 0x0003FF Interrupt vector table
; 0x000400 -> 0x0004FF BIOS data area
; 0x000500 -> 0x007BFF Unused (free memory, about 29.5 KB)
; 0x007C00 -> 0x007DFF Stage 1 (our bootloader)
; 0x007E00 -> 0x09FFFF Unused (free memory, about 608 KB)
; 0x0A0000 -> 0x0BFFFF Video RAM
; 0x0B0000 -> 0x0B7777 Monochrome video memory
; 0x0B8000 -> 0x0BFFFF Color video memory
; 0x0C0000 -> 0x0C7FFF Video ROM BIOS
; 0x0C8000 -> 0x0EFFFF BIOS shadow area
; 0x0F0000 -> 0x0FFFFF System BIOS
; 0x100000 -> Higher memory (unaccessible in real mode)

; In that area we must place:
; - Stage 2
; - Stack
; - Kernel / stage 3

; The approach taken in the default setting is to place stage 2 in memory 0x500.
; Stage 2 can then be 29 KB large. Stage 2 should only do whatever stuff needs
; to be done in real mode and then gather enough information to pass a multiboot
; structure to the kernel, so this should be enough. If this is not enough, it
; really should be separated into a stage 3.

; The kernel is loaded into 0x007E00, which has 608 KB of memory. This should be
; enough for most kernels that are using this loader, but if it's not enough we
; must move it to protected mode and drop back to real mode before loading more.


%ifndef __MMAP_S
%define __MMAP_S


; Address where stage 1 loads stage 2.
%define STAGE2_ADDR 0x0000
%define STAGE2_SEG  0x0050


; Where stage 1 is loaded at, as it should be interpreted when looking at the
; code.
%define STAGE1_ADDR 0x0000
%define STAGE1_SEG  0x07C0


; The start of the stack when stage 1 has finished. Stage 2 can either keep this
; or set up a new stack.
%define STAGE1_STACK 0x7BF0


%define STACK_START 0xFFFF


; Where we initially load the kernel when we are using the BIOS.
%define KERNEL_LOW_ADDR 0x7E00
%define KERNEL_LOW_SEG  0x0000
; Size in KB of this address space
%define KERNEL_LOW_SIZE 608


%endif
