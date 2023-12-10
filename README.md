<!-- <img align="left" style="vertical-align: middle" width="120" height="120" alt="Skiff Icon" src="data/icons/app.svg"> -->

# Submarine

An experimental bootloader for ChomeOS's depthcharge.

> [!WARNING]  
> Submarine is currently beta software. Please exercise care with your system and report any issues you encounter.

## 📕 Explainer
Submarine provides a minimal Linux environmemt that lives in a small partition (16mb) on the disk. We use this environment to bootstrap a full Linux system (or a different system if you're brave.)

Additional documention can be found on Fyra Developer (under construction!)


## 📦 Builds

We offer prebuilt versions of the images per each commit:

- [Latest x86_64 build](https://nightly.link/FyraLabs/submarine/workflows/build/main/submarine-x86_64.zip)
- [Latest arm64 build](https://nightly.link/FyraLabs/submarine/workflows/build/main/submarine-arm64.zip)

## 🛠️ Dependencies

Please make sure you have these dependencies first before building.

```bash
make
gcc
flex
bison
elfutils-devel
parted
vboot-utils
golang
xz
bc
openssl-devel
```

Additionally, you'll need to install u-root. To install the latest version:

```bash
go install github.com/u-root/u-root@latest
```

## 🏗️ Building

Simply clone this repo with submodules, so pass `--recurse-submodules` to `git clone`, then:

```bash
make -j$(nproc) <x86_64|arm64>
```

Please note that you **must** pass an architecture target.

The build output is located in `build/`.
For testing, an image is built at `build/submarine.bin` which you can directly flash onto an external drive.
So, for example, replace `/dev/sdX` with the device file of the external drive:

```bash
sudo dd if=build/submarine.bin of=/dev/sdX
```

## 🗒️ Todos

- Create kpart on arm
- Clean up kernel configs
