TOOLCHAIN_PREFIX=/opt/riscv32i/bin/riscv32-unknown-elf-
CC=$(TOOLCHAIN_PREFIX)gcc
AS=$(TOOLCHAIN_PREFIX)as
LD=$(TOOLCHAIN_PREFIX)ld
OBJCOPY=$(TOOLCHAIN_PREFIX)objcopy
SIZE=size

OBJ= \
	src/main.o \
	src/puts.o \
	src/dev/uart/wbuart32.o \
	src/dev/mu/mu.o \
	src/pp_printf/vsprintf-xint.o \
	src/pp_printf/printf.o \

CALSOC_ELF=calsoc.elf
CALSOC_BIN=calsoc.bin
CALSOC_HEX=calsoc.hex

SRC= \
	src/main \
	src/puts \
	src/dev/uart/wbuart32 \
	src/dev/mu/mu \
	src/pp_printf/vsprintf-xint \
	src/pp_printf/printf \

ASM_SRC= \
	bare_boot/start

LINKER_SCRIPT= sections.lds

OBJCOPY_FLAGS= -O binary 
CC_FLAGS=-c -Os -march=rv32im -Wall
START_ASM= bare_boot/start.s

LINK_OPT=-Os -ffreestanding -nostdlib -o $(CALSOC_ELF) \
		-Wl,-Bstatic,--strip-debug,-T,$(LINKER_SCRIPT) -lgcc 

.PHONY: boot firmware link

all: link
	@echo "finished"

firmware:
	@echo "src"
	$(foreach c_src, $(SRC), $(CC) $(CC_FLAGS) -o $(c_src).o $(c_src).c;)

link: firmware
	@echo "link"
	$(CC) $(LINK_OPT) $(START_ASM) $(OBJ)  
	$(SIZE) $(CALSOC_ELF)
	$(OBJCOPY) $(OBJCOPY_FLAGS) $(CALSOC_ELF) $(CALSOC_BIN)

clean:
	rm $(OBJ)
	rm $(CALSOC_ELF)
	rm $(CALSOC_BIN)