
BIN="stage1"

ASFLAGS="-I../common/"

all:
	nasm $(ASFLAGS) -f bin -o stage1 stage1.s
clean:
	-rm -f stage1 read floppy print

read:
	nasm -f bin -o read read.s
	
floppy:
	nasm -f bin -o floppy floppy.s

print:
	nasm -f bin -o print print.s
	

# Dump assembly code and object code so it's easier to see what is taking up
# space. To see a different binary use: make BIN=binary
dump:
	objdump -b binary -D -m i8086 $(BIN)

# make should not check if the file is up to date
.PHONY: all clean read dumpc floppy print
