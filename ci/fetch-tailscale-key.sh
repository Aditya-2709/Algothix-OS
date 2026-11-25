#!/usr/bin/env bash
set -euo pipefail

# Fetch the official Tailscale Debian 13 (trixie) signing key for live-build.
# Called by `make iso` before `lb build`.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEY_URL="https://pkgs.tailscale.com/stable/debian/trixie.noarmor.gpg"
KEY_OUT="${ROOT_DIR}/config/archives/tailscale.key.chroot"

if [ -s "${KEY_OUT}" ]; then
    echo "Tailscale signing key already present: ${KEY_OUT}"
    exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "ERROR: curl is required to fetch Tailscale signing key." >&2
    exit 1
fi

mkdir -p "$(dirname "${KEY_OUT}")"
curl -fsSL "${KEY_URL}" -o "${KEY_OUT}"
echo "Fetched Tailscale Debian trixie signing key -> ${KEY_OUT}"
