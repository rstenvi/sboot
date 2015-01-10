Overview of source code
============================

common/
-----------------

Code that is common for stage1 and stage2. It has the following files:

 - floppy.s - Reset floppy disk
 - mmap.s - Where thing should be placed in memory
 - vars.s - Default configuration
 - read.s - Read from disk using BIOS 0x13
 - print.s - Print string to screen


stage1/
------------

Code for the 512B stage 1. Almost all the code is in stage1.s.


stage2/
-------------

Code for stage 2, contains the following files:

 - stage2.s - Main file that ties everything together.
 - a20.s - Enable the A20 gate
 - gdt.s - Enable default GDT
 - memory.s - Get memory map from BIOS
 - multiboot.s - Parse the multiboot header of the OS
 - desf.s - A couple of definitions for stage 2

mbkernel/
-------------

Simple OS kernel to check that it works.


create\_disk.sh
-------------------------

Create a disk that can be booted from.


copy\_file.sh
-----------------------

Copy one or more files over to the bootable disk.


