TOOLCHAIN_PREFIX=/opt/riscv32i/bin/riscv32-unknown-elf-

.phony: test.o test.elf test.bin clean

OBJ= 	uart.o \
		main.o \
		putchar.o \
		# printf.o 

all: test.hex


%.o: %.c
	$(TOOLCHAIN_PREFIX)gcc -c -march=rv32im$(subst C,c,$(COMPRESSED_ISA)) -o $@ $<

test.elf: sections.lds start.s $(OBJ)
	$(TOOLCHAIN_PREFIX)gcc -Os -ffreestanding -nostdlib -o $@ \
		-Wl,-Bstatic,--strip-debug,-T,sections.lds \
		$^ -lgcc
		
test.bin: test.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@
	
test.hex: test.bin
	python3 makehex.py $^ > $@

clean:
	rm -f *.o test.elf test.bin test.hex
