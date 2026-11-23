#!/usr/bin/env bash
set -euo pipefail

# Install build and test dependencies on a Debian 13 (trixie) host or VM.
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Run this script as root (e.g., sudo ./ci/setup-env.sh)." >&2
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
    bats \
    ca-certificates \
    cpio \
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
    xorriso

echo "ALX build environment setup complete."
