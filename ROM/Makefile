%.bin : %.asm
	dasm $< -f3 -o$@

all : flt_test.bin

clean :
	rm -f *.bin
