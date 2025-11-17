{
  pkgs ? import <nixpkgs> { },
}:
with pkgs;
mkShell {
  name = "generic-cross-arm64";
  buildInputs = [
    # Tools
    clang-tools
    coreboot-utils
    dtc
    ubootTools
    # u-root
    go
    u-root
    # Linux deps
    ncurses
    pkg-config
    # Compiler
    pkgsCross.aarch64-multiplatform-musl.stdenv.cc
    (lib.hiPrio gcc)
  ]
  ++ linux.nativeBuildInputs;
  PKG_CONFIG_PATH = "${ncurses}/lib/pkgconfig";
  CROSS = "aarch64-unknown-linux-musl-";
}
