#!/usr/bin/env bash
set -euo pipefail

# Security test (PRD FR-7.3 & M5 AC):
# Verify that `ss -tulpn` reports zero externally listening TCP/UDP services
# (ports bound to 0.0.0.0, ::, or * outside loopback 127.0.0.0/8 and ::1).

if ! command -v ss >/dev/null 2>&1; then
    echo "ERROR: 'ss' (iproute2) is required." >&2
    exit 1
fi

echo "==> Checking listening sockets (ss -tulpn)"
RAW_OUT="$(ss -tulpnH 2>/dev/null || true)"

PUBLIC_LISTENERS="$(printf '%s\n' "${RAW_OUT}" | awk '
    NF >= 5 {
        addr = $5
        if (addr ~ /^127\./ || addr ~ /^\[::1\]/ || addr ~ /^::1:/ || addr ~ /%lo:/) {
            next
        }
        print $0
    }
')"

if [ -n "${PUBLIC_LISTENERS}" ]; then
    echo "FAIL: Externally listening services detected:" >&2
    printf '%s\n' "${PUBLIC_LISTENERS}" >&2
    exit 1
fi

echo "PASS: No externally listening TCP/UDP services detected."
exit 0
