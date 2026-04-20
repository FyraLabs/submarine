#
# Submarine build env
#
# build docker image:
#   podman build -t submarine/buildenv .
#
# run:
#   podman run --rm -v ".:/submarine" submarine/buildenv                           #x86_64 build (default)
#   podman run --rm -v ".:/submarine" submarine/buildenv make -j$(nproc) arm64     #arm64 build
#   podman run --rm -v ".:/submarine" submarine/buildenv make clean                #clean
#
FROM fedora-minimal:latest
RUN dnf install -y --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release && \
    dnf update -y && dnf install -y \
    awk \
    bc \
    bison \
    ccache \
    depthcharge-tools \
    elfutils-devel \
    flex \
    gcc \
    gcc-aarch64-linux-gnu \
    golang \
    make \
    openssl-devel \
    openssl-devel-engine \
    patch \
    parted \
    perl \
    tar \
    uboot-tools \
    vboot-utils \
    xz \
    && rm -rf /var/cache/libdnf5/*
RUN go install github.com/u-root/u-root@latest
ENV PATH="/root/go/bin:${PATH}"
WORKDIR /submarine
CMD make -j$(nproc) x86_64
