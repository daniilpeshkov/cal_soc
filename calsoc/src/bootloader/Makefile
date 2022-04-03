TOOLCHAIN_PREFIX=/opt/riscv32i/bin/riscv32-unknown-elf-

.phony: bootloader.o bootloader.elf bootloader.bin clean

OBJ= main.o

all: bootloader.hex

%.o: %.c
	$(TOOLCHAIN_PREFIX)gcc -c -march=rv32im$(subst C,c,$(COMPRESSED_ISA)) -o $@ $<

bootloader.elf: sections.lds start.s $(OBJ)
	$(TOOLCHAIN_PREFIX)gcc -Os -ffreestanding -nostdlib -o $@ \
		-Wl,-Bstatic,--strip-debug,-T,sections.lds \
		$^ -lgcc
		
bootloader.bin: bootloader.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@
	
bootloader.hex: bootloader.bin
	python3 ../makehex.py $^ > $@

clean:
	rm -f *.o bootloader.elf bootloader.bin bootloader.hex
