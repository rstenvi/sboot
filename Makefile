
all: sys

sys:
	make -C ./src floppy

run-bochs: sys
	$(BOCHS) -q -f .bochsrc.txt

run-qemu: sys
	qemu-system-i386 -fda src/floppy.img

# Requires root
run-qemu-tpm: sys
	qemu-system-i386 -tpmdev passthrough,id=tpm0 -device tpm-tis,tpmdev=tpm0 -fda src/floppy.img

clean:
	make -C ./src clean
	-rm -f bochsout.txt

.PHONY: all sys clean run-bochs run-qemu
