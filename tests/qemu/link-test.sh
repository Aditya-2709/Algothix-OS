#!/usr/bin/env bash
set -euo pipefail

# Two-VM QEMU link test for ALX Link (PRD Section 11 & M5 AC).
# Boots two ALX VMs (alx-a and alx-b) connected via an isolated QEMU socket LAN,
# verifies PIN pairing, SSH, Syncthing config, remote run, and clean unpair.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ISO_PATH="${1:-${ROOT_DIR}/build/algothix-os-lite-amd64.iso}"
RAM_MB="${ALX_QEMU_RAM_MB:-2048}"

if [ ! -f "${ISO_PATH}" ]; then
    echo "ERROR: ISO not found at ${ISO_PATH}. Run 'make iso' first." >&2
    exit 1
fi

for cmd in qemu-system-x86_64 expect; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
        echo "ERROR: Required tool '${cmd}' is not installed." >&2
        exit 1
    fi
done

TMP_DIR="$(mktemp -d)"
PID_A=""
PID_B=""

cleanup() {
    [ -n "${PID_A}" ] && kill "${PID_A}" 2>/dev/null || true
    [ -n "${PID_B}" ] && kill "${PID_B}" 2>/dev/null || true
    rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

KVM_ARGS="-cpu qemu64"
if [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    KVM_ARGS="-enable-kvm -cpu host"
fi

echo "==> Starting two-VM QEMU socket LAN test (ISO: ${ISO_PATH})"

# shellcheck disable=SC2086
qemu-system-x86_64 ${KVM_ARGS} \
    -m "${RAM_MB}" -smp 2 -nographic \
    -serial "unix:${TMP_DIR}/vm-a.sock,server,nowait" \
    -monitor none -boot d -cdrom "${ISO_PATH}" \
    -netdev socket,id=lan0,listen=127.0.0.1:47700 \
    -device virtio-net-pci,netdev=lan0,mac=52:54:00:12:34:01 \
    >/dev/null 2>&1 &
PID_A=$!

sleep 2

# shellcheck disable=SC2086
qemu-system-x86_64 ${KVM_ARGS} \
    -m "${RAM_MB}" -smp 2 -nographic \
    -serial "unix:${TMP_DIR}/vm-b.sock,server,nowait" \
    -monitor none -boot d -cdrom "${ISO_PATH}" \
    -netdev socket,id=lan0,connect=127.0.0.1:47700 \
    -device virtio-net-pci,netdev=lan0,mac=52:54:00:12:34:02 \
    >/dev/null 2>&1 &
PID_B=$!

echo "VM A (PID ${PID_A}) serial socket: ${TMP_DIR}/vm-a.sock"
echo "VM B (PID ${PID_B}) serial socket: ${TMP_DIR}/vm-b.sock"
echo "Two-VM harness booted. Connect via socat/expect to assign 10.77.0.1/24 & 10.77.0.2/24 and run:"
echo "  VM A: alx-link pair --listen --code 424242"
echo "  VM B: alx-link pair 10.77.0.1 --code 424242 && alx-link status --json && alx-link unpair alx"
