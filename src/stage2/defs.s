; defs.s
; Constants and configuration of stage 2

%ifndef __DEFS_S
%define __DEFS_S

%include "vars.s"

; Size of kernel
%define KERNEL_SECTORS 32


; There are some simple functional differences between MB1 and MB2 that are
; handled here.
%if MB_VERSION = 1
	%define MB_SIG 0x1BADB002
	%define MB_EAX 0x2BADB002
	%define MB_ALIGN 4
	%define MB_MAX 8192
%elif MB_VERSION = 2
	%define MB_SIG 0xE85250D6
	%define MB_ALIGN 8
	%define MB_MAX 32768
	%define MB_EAX 0x36D76289
%endif

; We don't support video mode, if it asks for it we cannot boot the kernel
%define MB_NOT_SUPPORTED 4

; What we require the OS to set. Since we don't know how to parse ELF files, we
; need to know some information about the executable.
%define MB_REQUIRED (1 << 16)

%endif
