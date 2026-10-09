{
  pkgs ? import <nixpkgs> { },
}:
with pkgs;
mkShell {
  name = "submarine-dev";
  buildInputs = [
    # Tools
    clang-tools
    coreboot-utils
    # submarine
    go
    u-root
    depthcharge-tools
    parted
    ubootTools
    util-linux
    vboot_reference
    # dev deps
    ncurses
    pkg-config
    # Compiler
    coreboot-toolchain.aarch64
    coreboot-toolchain.x64
    (lib.hiPrio gcc)
  ]
  ++ linux.nativeBuildInputs;
  PKG_CONFIG_PATH = "${ncurses}/lib/pkgconfig";
  CROSS = "aarch64-elf-";
}
