

all: deps

deps:
	make -C ./stage1
	make -C ./stage2
	make -C ./mbkernel

floppy: deps
	./create_disk.sh
	./copy_file.sh --fs none stage1/stage1 stage2/stage2 mbkernel/kernel

ext2: deps
	./create_disk.sh -f ext2
	./copy_file.sh -f none stage1/stage1
	./copy_file.sh -f ext2 stage2/stage2 mbkernel/kernel

clean:
	make -C ./stage1 clean
	make -C ./stage2 clean
	make -C ./mbkernel clean
	-rm -f floppy.img



.PHONY: all clean deps floppy ext2

