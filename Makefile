project_name = submarine

# Common directories
WORKDIR=build
CONFDIR=configs
OUTPUTDIR=images
TMPFILE=/tmp/$(project_name)

CONFIG_X64=kernel.x86
BZIMAGE_X64=bzImage.x86
INITFS_X64=u-root-x86.cpio
INITFSZ_X64=u-root-x86.cpio.xz
KPART_X64=$(project_name)-x86.kpart
IMG_X64=$(project_name)-x86.bin

CONFIG_A64=kernel.a64
BZIMAGE_A64=bzImage.a64
INITFS_A64=u-root-a64.cpio
INITFSZ_A64=u-root-a64.cpio.xz
KPART_A64=$(project_name)-a64.kpart
IMG_A64=$(project_name)-a64.bin

.PHONY: usage

ifeq ($(shell uname -m), x86_64)
        CROSS=aarch64-linux-gnu-
endif

usage:
	@echo "usage: make [x86_64|arm64]"

# Use 'make: x86_64' to build x86 image.
x86_64: $(IMG_X64)
$(IMG_X64): $(KPART_X64)
	fallocate -l 18M $(WORKDIR)/$(IMG_X64)
	parted $(WORKDIR)/$(IMG_X64) mklabel gpt --script
	cgpt add -i 1 -t kernel -b 2048 -s 32767 -P 15 -T 1 -S 1 $(WORKDIR)/$(IMG_X64)
	dd if=$(WORKDIR)/$(KPART_X64) of=$(WORKDIR)/$(IMG_X64) bs=512 seek=2048 conv=notrunc
	cp $(WORKDIR)/$(IMG_X64) $(OUTPUTDIR)/$(IMG_X64)
	@echo 'Build complete! Resulting file saved as "$(IMG_X64)" in "images" directory.'

$(KPART_X64): $(BZIMAGE_X64)
	echo $(project_name) > $(TMPFILE)
	futility vbutil_kernel --pack $(WORKDIR)/$(KPART_X64) --signprivate /usr/share/vboot/devkeys/kernel_data_key.vbprivk --keyblock /usr/share/vboot/devkeys/kernel.keyblock --config $(TMPFILE) --bootloader $(TMPFILE) --vmlinuz $(WORKDIR)/$(BZIMAGE_X64) --version 1 --arch x86
	mkdir -p $(OUTPUTDIR)
	cp $(WORKDIR)/$(KPART_X64) $(OUTPUTDIR)/$(KPART_X64)
	@echo 'Kernel partition binary saved as "$(KPART_X64)" in "images" directory.'

$(BZIMAGE_X64): $(INITFSZ_X64)
	cp $(CONFDIR)/$(CONFIG_X64) kernel/.config
	make -C kernel olddefconfig
	make -C kernel
	cp kernel/arch/x86/boot/bzImage $(WORKDIR)/$(BZIMAGE_X64)

$(INITFSZ_X64): $(INITFS_X64)
	xz -kf -9 --check=crc32 $(WORKDIR)/$(INITFS_X64)

$(INITFS_X64):
	mkdir -p build
	GBB_PATH=u-root u-root -o $(WORKDIR)/$(INITFS_X64) -uinitcmd="elvish -c 'sleep 3; boot'" core ./cmds/boot/boot


# Use 'make arm64' to build ARM64 (cross-compiling is supported).
arm64: $(IMG_A64)
$(IMG_A64): $(KPART_A64)
	fallocate -l 18M $(WORKDIR)/$(IMG_A64)
	parted $(WORKDIR)/$(IMG_A64) mklabel gpt --script
	cgpt add -i 1 -t kernel -b 2048 -s 32767 -P 15 -T 1 -S 1 $(WORKDIR)/$(IMG_A64)
	dd if=$(WORKDIR)/$(KPART_A64) of=$(WORKDIR)/$(IMG_A64) bs=512 seek=2048 conv=notrunc
	cp $(WORKDIR)/$(IMG_A64) $(OUTPUTDIR)/$(IMG_A64)
	@echo 'Build complete! Resulting file saved as "$(IMG_A64)" in "images" directory.'

$(KPART_A64): $(BZIMAGE_A64)
	depthchargectl build -v \
		--board arm64-generic \
		--kernel $(WORKDIR)/$(BZIMAGE_A64) \
		--fdtdir $(WORKDIR)/dtbs \
		--root none \
		--kernel-cmdline "" \
		--output $(WORKDIR)/$(KPART_A64)
	mkdir -p $(OUTPUTDIR)
	cp $(WORKDIR)/$(KPART_A64) $(OUTPUTDIR)/$(KPART_A64)
	@echo 'Kernel partition binary saved as "$(KPART_A64)" in "images" directory.'

$(BZIMAGE_A64): $(INITFSZ_A64)
	cp $(CONFDIR)/$(CONFIG_A64) kernel/.config
	CROSS_COMPILE=$(CROSS) ARCH=arm64 make -C kernel olddefconfig
	CROSS_COMPILE=$(CROSS) ARCH=arm64 make -C kernel
	CROSS_COMPILE=$(CROSS) ARCH=arm64 make -C kernel dtbs_install INSTALL_DTBS_PATH=../$(WORKDIR)/dtbs
	cp kernel/arch/arm64/boot/Image.gz $(WORKDIR)/$(BZIMAGE_A64)

$(INITFSZ_A64): $(INITFS_A64)
	xz -kf -9 --check=crc32 $(WORKDIR)/$(INITFS_A64)

$(INITFS_A64):
	mkdir -p build images
	GBB_PATH=u-root GOOS=linux GOARCH=arm64 u-root -o $(WORKDIR)/$(INITFS_A64) -uinitcmd="elvish -c 'sleep 3; boot'" core ./cmds/boot/boot

clean:
	rm -rf $(WORKDIR)
