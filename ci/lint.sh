#!/usr/bin/env bash
set -euo pipefail

# Run shellcheck on all shell scripts and lintian on all built .deb packages.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

echo "==> Running shellcheck"
if ! command -v shellcheck >/dev/null 2>&1; then
    echo "ERROR: shellcheck is not installed." >&2
    exit 1
fi

mapfile -t shell_files < <(
    find auto ci config/hooks tests/qemu packages \
        -type f \( -name "*.sh" -o -name "*.chroot" -o -name "config" -o -name "build" -o -name "clean" -o -path "packages/*/usr/bin/alx-*" \) \
        -not -path "packages/*/etc/*" \
        2>/dev/null | sort
)

if [ "${#shell_files[@]}" -gt 0 ]; then
    shellcheck -S warning "${shell_files[@]}"
    echo "shellcheck passed (${#shell_files[@]} files)."
else
    echo "No shell files found for shellcheck."
fi

echo "==> Running lintian"
if ! command -v lintian >/dev/null 2>&1; then
    echo "ERROR: lintian is not installed." >&2
    exit 1
fi

shopt -s nullglob
debs=(build/debs/*.deb)
shopt -u nullglob

if [ "${#debs[@]}" -gt 0 ]; then
    lintian --fail-on error "${debs[@]}"
    echo "lintian passed (${#debs[@]} packages)."
else
    echo "No built .deb packages in build/debs/ yet (run 'make packages' first)."
fi
