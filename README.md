sboot
=====================

Simple bootloader that attempts to be Multiboot 1 and 2 compliant.


Status of project
----------------------

Unfinished! Only supports loading kernels from a flat FS and only Multiboot 1.
Only tested with emulated floppy in Bochs and Qemu. Should NOT be used for
anything serious.


Components
----------------------

Below are the components in src.

- stage1 - Just loads stage 2 and runs it ( < 512B)
- stage2 - Loads and execute the kernel according to MB1
- mbkernel - A sample kernel that has been tested with the bootloader
- common - Assembly code that is statically shared between stage1 and stage2

Building
----------------

A test kernel can be built with NASM and GCC Cross-compiler. Bochs or Qemu is
also required, if Bochs is used, the program executable must be placed in
environmental variable $BOCHS.

