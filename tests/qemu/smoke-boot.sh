#!/usr/bin/env bash
set -euo pipefail

# QEMU BIOS + UEFI smoke test for Algothix OS (ALX) Lite ISO.
# Boots with 2 GB RAM and a throttled virtual HDD, checks login prompt,
# verifies /etc/os-release and hostname, and reports ISO size, boot time, and idle RAM.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ISO_PATH="${1:-${ROOT_DIR}/build/algothix-os-lite-amd64.iso}"
RAM_MB="${ALX_QEMU_RAM_MB:-2048}"
TIMEOUT_SEC="${ALX_QEMU_TIMEOUT:-180}"
MAX_ISO_MB=1536

if [ ! -f "${ISO_PATH}" ]; then
    echo "ERROR: ISO not found at ${ISO_PATH}. Run 'make iso' first." >&2
    exit 1
fi

for cmd in qemu-system-x86_64 qemu-img expect; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
        echo "ERROR: Required tool '${cmd}' is not installed." >&2
        exit 1
    fi
done

OVMF_CODE=""
for candidate in \
    /usr/share/OVMF/OVMF_CODE_4M.fd \
    /usr/share/OVMF/OVMF_CODE.fd \
    /usr/share/ovmf/OVMF.fd; do
    if [ -f "${candidate}" ]; then
        OVMF_CODE="${candidate}"
        break
    fi
done

if [ -z "${OVMF_CODE}" ]; then
    echo "ERROR: OVMF UEFI firmware not found (install package 'ovmf')." >&2
    exit 1
fi

iso_bytes="$(stat -c%s "${ISO_PATH}")"
iso_mb="$((iso_bytes / 1024 / 1024))"
echo "==> ISO: ${ISO_PATH} (${iso_mb} MiB)"
if [ "${iso_mb}" -gt "${MAX_ISO_MB}" ]; then
    echo "FAIL: ISO size ${iso_mb} MiB exceeds ${MAX_ISO_MB} MiB budget (PRD Section 7)." >&2
    exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

DISK_IMG="${TMP_DIR}/alx-hdd.qcow2"
qemu-img create -f qcow2 "${DISK_IMG}" 20G >/dev/null

KVM_ARGS=""
if [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    KVM_ARGS="-enable-kvm -cpu host"
else
    KVM_ARGS="-cpu qemu64"
fi

run_mode() {
    local mode="$1"
    local log_file="${TMP_DIR}/qemu-${mode}.log"
    local uefi_args=""

    if [ "${mode}" = "uefi" ]; then
        uefi_args="-drive if=pflash,format=raw,readonly=on,file=${OVMF_CODE}"
    fi

    echo ""
    echo "==> Running QEMU smoke test (${mode^^}, ${RAM_MB} MB RAM, throttled HDD)"
    # shellcheck disable=SC2086
    expect "${SCRIPT_DIR}/smoke-boot.expect" \
        "${TIMEOUT_SEC}" \
        "${log_file}" \
        qemu-system-x86_64 \
        ${KVM_ARGS} \
        -m "${RAM_MB}" \
        -smp 2 \
        -nographic \
        -serial stdio \
        -monitor none \
        -boot d \
        -cdrom "${ISO_PATH}" \
        -drive "file=${DISK_IMG},format=qcow2,if=ide,bps=83886080,iops=150" \
        ${uefi_args}

    echo "==> ${mode^^} smoke test PASSED"
}

run_mode "bios"
run_mode "uefi"

echo ""
echo "ALL QEMU SMOKE TESTS PASSED (ISO: ${iso_mb} MiB, BIOS + UEFI, ${RAM_MB} MB RAM)"
