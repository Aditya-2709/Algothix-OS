FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bats \
    build-essential \
    ca-certificates \
    cpio \
    curl \
    debhelper \
    debootstrap \
    devscripts \
    dpkg-dev \
    expect \
    fakeroot \
    git \
    gnupg \
    grub-efi-amd64-bin \
    grub-pc-bin \
    isolinux \
    lintian \
    live-build \
    make \
    mtools \
    ovmf \
    qemu-system-x86 \
    qemu-utils \
    reprepro \
    shellcheck \
    squashfs-tools \
    syslinux-common \
    xorriso \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
CMD ["make", "help"]
