#!/usr/bin/env bash
set -euo pipefail

# Multi-user memory isolation test (PRD M7 AC).
# Runs inside a booted ALX VM as root: creates user_a and user_b via alx-adduser
# with tight MemoryMax limits, starts a sentinel process in user_b's slice,
# triggers a memory hog in user_a's slice with stress-ng, and asserts that
# user_b's sentinel survives unharmed.

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Run this test as root inside a booted ALX VM." >&2
    exit 1
fi

for cmd in alx-adduser systemd-run stress-ng; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
        echo "ERROR: Required command '${cmd}' not found (install stress-ng for this test)." >&2
        exit 1
    fi
done

alx-adduser alxtesta --memory-max 256
alx-adduser alxtestb --memory-max 256

UID_A="$(id -u alxtesta)"
UID_B="$(id -u alxtestb)"

echo "==> Starting sentinel process in user-${UID_B}.slice (alxtestb)"
systemd-run --uid="${UID_B}" --slice="user-${UID_B}.slice" --unit="alx-sentinel-b" sleep 60

echo "==> Running memory hog (512 MB > 256 MB MemoryMax) in user-${UID_A}.slice (alxtesta)"
systemd-run --wait --uid="${UID_A}" --slice="user-${UID_A}.slice" \
    stress-ng --vm 1 --vm-bytes 512M --vm-keep --timeout 10s || true

echo "==> Checking that user-${UID_B}.slice sentinel is still active"
if systemctl is-active --quiet alx-sentinel-b.service; then
    systemctl stop alx-sentinel-b.service || true
    echo "PASS: User B session survived User A's memory hog cleanly."
    exit 0
else
    echo "FAIL: User B's sentinel process was terminated." >&2
    exit 1
fi
