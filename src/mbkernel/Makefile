
C_SOURCES=$(wildcard *.c)
ASM_SOURCES=$(wildcard *.s)
OBJ=${ASM_SOURCES:.s=.o}
OBJ+=${C_SOURCES:.c=.o}


AS=nasm
ASFLAGS=-Iinc/ -felf32

CFLAGS=-nostdlib -ffreestanding -O2 -Wall -Wextra -m32

CC=i686-elf-gcc
LD=i686-elf-gcc


LDFLAGS=-T linker.ld
LDFLAGS2=-nostdlib -ffreestanding -lgcc -z max-page-size=0x1000


all: $(OBJ) kernel

kernel: $(OBJ)
	$(LD) $(LDFLAGS) -o kernel $(OBJ) $(LDFLAGS2)

# Can also check it against Grub 
run-grub: all
	cp kernel iso/boot/
	$(GRUB_RESCUE) -o image.iso iso/
	qemu-system-i386 -cdrom image.iso

clean:
	-rm -f *.o kernel image.iso iso/boot/kernel

.PHONY: all clean run-grub

