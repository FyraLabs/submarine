project_name = cr-boot

# Common directories
WORKDIR=build
CONFDIR=configs
OUTPUTDIR=images

# x86 machines use common kernel configuration
CONFIG_X64=kernel.x86
BZIMAGE_X64=bzImage.x86
INITFS_X64=u-root-x86.cpio
INITFSZ_X64=u-root-x86.cpio.xz
KPART_X64=crboot-x86.kpart
IMG_X64=crboot-x86.bin

# The only supported ARM64 platform right now is MediaTek MT8183.
CONFIG_MT8183=kernel.mt8183
BZIMAGE_A64=bzImage.a64
INITFS_A64=u-root-a64.cpio
INITFSZ_A64=u-root-a64.cpio.xz
KPART_A64=crboot-a64.kpart
IMG_A64=crboot-a64.bin

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
	echo crboot-x86_64 > /tmp/crboot-x86_64
	futility vbutil_kernel --pack $(WORKDIR)/$(KPART_X64) --signprivate /usr/share/vboot/devkeys/kernel_data_key.vbprivk --keyblock /usr/share/vboot/devkeys/kernel.keyblock --config /tmp/crboot-x86_64 --bootloader /tmp/crboot-x86_64 --vmlinuz $(WORKDIR)/$(BZIMAGE_X64) --version 1 --arch x86

$(BZIMAGE_X64): $(INITFSZ_X64)
	cp $(CONFDIR)/$(CONFIG_X64) kernel/.config
	make -j8 -C kernel
	cp kernel/arch/x86/boot/bzImage $(WORKDIR)/$(BZIMAGE_X64)

$(INITFSZ_X64): $(INITFS_X64)
	xz -kf -9 --check=crc32 $(WORKDIR)/$(INITFS_X64)

$(INITFS_X64):
	mkdir -p build
	GBB_PATH=u-root go run ./u-root -o $(WORKDIR)/$(INITFS_X64) -uinitcmd="elvish -c 'sleep 3; boot'" core ./cmds/boot/boot


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
	echo crboot-arm64 > /tmp/crboot-arm64
	futility vbutil_kernel --pack $(WORKDIR)/$(KPART_A64) --signprivate /usr/share/vboot/devkeys/kernel_data_key.vbprivk --keyblock /usr/share/vboot/devkeys/kernel.keyblock --config /tmp/crboot-arm64 --bootloader /tmp/crboot-arm64 --vmlinuz $(WORKDIR)/$(BZIMAGE_A64) --version 1 --arch arm64

$(BZIMAGE_A64): $(INITFSZ_A64)
	cp $(CONFDIR)/$(CONFIG_MT8183) kernel/.config
	ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make -j8 -C kernel
	cp kernel/arch/arm64/boot/Image.gz $(WORKDIR)/$(BZIMAGE_A64)

$(INITFSZ_A64): $(INITFS_A64)
	xz -kf -9 --check=crc32 $(WORKDIR)/$(INITFS_A64)

$(INITFS_A64):
	mkdir -p build images
	GBB_PATH=u-root GOOS=linux GOARCH=arm64 go run ./u-root -o $(WORKDIR)/$(INITFS_A64) -uinitcmd="elvish -c 'sleep 3; boot'" core ./cmds/boot/boot
	
clean:
	rm -rf $(WORKDIR)
