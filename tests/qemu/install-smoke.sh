#!/usr/bin/env bash
set -euo pipefail

# QEMU install smoke test harness (PRD Section 11 & M6 AC).
# Creates a 20 GB virtual HDD, boots the live ISO with 2 GB RAM for Calamares
# installation, and provides a second-boot command to verify installed first-boot
# alx-tune and alx-welcome.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ISO_PATH="${1:-${ROOT_DIR}/build/algothix-os-lite-amd64.iso}"
DISK_IMG="${2:-${ROOT_DIR}/build/alx-install-test.qcow2}"
RAM_MB="${ALX_QEMU_RAM_MB:-2048}"

if [ ! -f "${ISO_PATH}" ]; then
    echo "ERROR: ISO not found at ${ISO_PATH}. Run 'make iso' first." >&2
    exit 1
fi

for cmd in qemu-system-x86_64 qemu-img; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
        echo "ERROR: Required tool '${cmd}' is not installed." >&2
        exit 1
    fi
done

mkdir -p "$(dirname "${DISK_IMG}")"
if [ ! -f "${DISK_IMG}" ]; then
    qemu-img create -f qcow2 "${DISK_IMG}" 20G
fi

KVM_ARGS="-cpu qemu64"
if [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    KVM_ARGS="-enable-kvm -cpu host"
fi

echo "==> Booting live ISO for installation onto ${DISK_IMG} (2 GB RAM, HDD throttle)"
echo "    1) Run 'Install Algothix OS (ALX) Lite' (alx-calamares-launch)."
echo "    2) After install finishes, shut down and re-run with --boot-installed."

if [ "${3:-}" = "--boot-installed" ]; then
    # shellcheck disable=SC2086
    exec qemu-system-x86_64 ${KVM_ARGS} \
        -m "${RAM_MB}" -smp 2 -boot c \
        -drive "file=${DISK_IMG},format=qcow2,if=ide,bps=83886080,iops=150"
else
    # shellcheck disable=SC2086
    exec qemu-system-x86_64 ${KVM_ARGS} \
        -m "${RAM_MB}" -smp 2 -boot d \
        -cdrom "${ISO_PATH}" \
        -drive "file=${DISK_IMG},format=qcow2,if=ide,bps=83886080,iops=150"
fi
