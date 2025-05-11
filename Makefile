ASM=nasm
CXX=g++     # Using standard g++ instead of cross-compiler
LD=ld

SRC_DIR=src
BUILD_DIR=build
KERNEL_DIR=$(SRC_DIR)/kernel

# Simplified flags that should work with standard compilers
CXXFLAGS=-m32 -fno-pie -ffreestanding -nostdlib -fno-exceptions -fno-rtti -O2
LDFLAGS=-m elf_i386 -Ttext 0x1000 --oformat binary

.PHONY: all floppy_image kernel bootloader clean always run

# Default target
all: floppy_image

#
# FLOPPY IMAGE
#
floppy_image: ${BUILD_DIR}/main_floppy.img

${BUILD_DIR}/main_floppy.img: bootloader kernel
	dd if=/dev/zero of=${BUILD_DIR}/main_floppy.img bs=512 count=2880
	dd if=${BUILD_DIR}/bootloader.bin of=${BUILD_DIR}/main_floppy.img bs=512 count=1 conv=notrunc
	dd if=${BUILD_DIR}/kernel.bin of=${BUILD_DIR}/main_floppy.img bs=512 seek=1 count=20 conv=notrunc

#
# BOOTLOADER
#
bootloader: ${BUILD_DIR}/bootloader.bin

${BUILD_DIR}/bootloader.bin: always
	${ASM} ${SRC_DIR}/bootloader/boot.asm -f bin -o ${BUILD_DIR}/bootloader.bin

#
# KERNEL
#
kernel: ${BUILD_DIR}/kernel.bin

# For now, we'll use a simpler assembly-only kernel to get things working
${BUILD_DIR}/kernel.bin: ${KERNEL_DIR}/main.asm always
	${ASM} $< -f bin -o $@

# Keeping this commented out until we get the cross-compiler working
# ${BUILD_DIR}/kernel.bin: ${BUILD_DIR}/kernel_entry.o ${BUILD_DIR}/kernel.o always
#	$(LD) $(LDFLAGS) -o ${BUILD_DIR}/kernel.bin $^

# ${BUILD_DIR}/kernel_entry.o: ${KERNEL_DIR}/kernel_entry.asm always
#	${ASM} -f elf $< -o $@

# ${BUILD_DIR}/kernel.o: ${KERNEL_DIR}/kernel.cpp ${KERNEL_DIR}/kernel.h always
#	$(CXX) $(CXXFLAGS) -c $< -o $@

#
# ALWAYS
#
always:
	mkdir -p ${BUILD_DIR}

#
# RUN
#
run: floppy_image
	qemu-system-i386 -fda ${BUILD_DIR}/main_floppy.img

#
# CLEAN
#
clean: 
	rm -rf ${BUILD_DIR}/*

#
# HELP
#
help:
	@echo "Available targets:"
	@echo "  all          - Build everything (default)"
	@echo "  floppy_image - Build floppy disk image"
	@echo "  bootloader   - Build bootloader only"
	@echo "  kernel       - Build kernel only"
	@echo "  run          - Run OS in QEMU"
	@echo "  clean        - Remove all build files"