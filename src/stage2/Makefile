
# Point is that it should be possible to overload variables
# Insert includes in our environment
NASMENVI:=-i ../common/ -iinc/ $(shell echo $(NASMENV))
export NASMENV=$(NASMENVI)

ASFLAGS=

all:
	nasm $(ASFLAGS) -f bin -o stage2 stage2.s

clean:
	-rm -f stage2

.PHONY: all clean
