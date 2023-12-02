BZIMAGE=build/bzImage
INITFS=build/initramfs.cpio
INITFSZ=build/initramfs.cpio.xz
KPART=build/crboot.kpart

.PHONY: clean

all: $(KPART)

$(KPART): $(BZIMAGE)
	echo crboot > /tmp/crboot
	futility vbutil_kernel --pack $(KPART) --signprivate /usr/share/vboot/devkeys/kernel_data_key.vbprivk --keyblock /usr/share/vboot/devkeys/kernel.keyblock --config /tmp/crboot --bootloader /tmp/crboot --vmlinuz $(BZIMAGE) --version 1 --arch x86

$(BZIMAGE): $(INITFSZ)
	make -C kernel
	cp kernel/arch/x86/boot/bzImage $(BZIMAGE)

$(INITFSZ): $(INITFS)
	xz -kf -9 --check=crc32 $(INITFS)

$(INITFS):
	mkdir -p build
	GBB_PATH=u-root u-root -o $(INITFS) -uinitcmd=boot core ./cmds/boot/boot

clean:
	rm -rf build
