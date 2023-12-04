BZIMAGE=build/bzImage
INITFS=build/initramfs.cpio
INITFSZ=build/initramfs.cpio.xz
KPART=build/crboot.kpart
IMG=build/crboot.bin

.PHONY: clean

all: $(IMG)

$(IMG): $(KPART)
	fallocate -l 18M $(IMG)
	parted $(IMG) mklabel gpt --script
	cgpt add -i 1 -t kernel -b 2048 -s 32767 -P 15 -T 1 -S 1 $(IMG)
	dd if=$(KPART) of=$(IMG) bs=512 seek=2048 conv=notrunc

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
	GBB_PATH=u-root u-root -o $(INITFS) -uinitcmd="elvish -c 'sleep 3; boot'" core ./cmds/boot/boot

clean:
	rm -rf build
