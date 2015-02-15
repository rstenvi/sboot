; vars.s
; Constants to change the functionality of the loader.
; This is to change default behaviour, it can also be overloaded on the command
; line.


%ifndef __VARS_H
%define __VARS_H

; ---------------- Variable constants  --------------------------

; Implement true, false functionality
%define TRUE 1
%define FALSE 0


; Different devices we can be booted from
%define DEV_FLOPPY 1
%define DEV_ATA    2


; Different filesystems we can use
%define FS_NONE 0
%define FS_EXT2 1


; Assume 3.5" floppy:
; See: http://www.pcguide.com/ref/fdd/mediaGeometry-c.html
%define DEFAULT_NUM_HEADS 2
%define DEFAULT_NUM_TRACKS 18




; --------------- Parameters to configure -----------------------------------

; Which file system is used, possible values are:
; - FS_NONE (No file system, everything is interpreted as one block)
%ifndef FS
	%define FS FS_NONE
;	%define FS FS_EXT2
%endif

; What kind of HW device is being used, possible values are:
; - DEV_FLOPPY (floppy disk)
; - DEV_ATA (ATA disk)
%ifndef DRIVE
	%define DRIVE DEV_FLOPPY
;	%define DRIVE DEV_ATA
%endif


; Which Multiboot version is used, 1 or 2.
%ifndef MB_VERSION
	%define MB_VERSION 1
;	%define MB_VERSION 2
%endif


; Whether or not we should exclude all non-essential code from stage 1. This
; includes stuff like printing, both error and information.
%ifndef MINIMIZE
	%define MINIMIZE FALSE
%endif

; Which stage is currently assembling
%ifndef STAGE
	%define STAGE 1
%endif


%ifndef STAGE2_SECTORS
	%define STAGE2_SECTORS 7
%endif

%ifndef SHA1_BIG_ENDIAN
	%define SHA1_BIG_ENDIAN TRUE
%endif

%endif
