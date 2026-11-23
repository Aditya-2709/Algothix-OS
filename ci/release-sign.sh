#!/usr/bin/env bash
set -euo pipefail

# Generate SHA256SUMS and detached GPG signatures for ALX Lite release artifacts (FR-7.6).
# Usage: ./ci/release-sign.sh <artifact-file> [output-dir]

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <artifact-file> [output-dir]" >&2
    exit 2
fi

ARTIFACT="$1"
OUT_DIR="${2:-$(dirname "${ARTIFACT}")}"
BASENAME="$(basename "${ARTIFACT}")"

if [ ! -f "${ARTIFACT}" ]; then
    echo "ERROR: Artifact not found: ${ARTIFACT}" >&2
    exit 1
fi

mkdir -p "${OUT_DIR}"

(
    cd "$(dirname "${ARTIFACT}")"
    sha256sum "${BASENAME}" > "${OUT_DIR}/SHA256SUMS"
)
echo "Generated ${OUT_DIR}/SHA256SUMS"

if command -v gpg >/dev/null 2>&1 && [ -n "${ALX_GPG_KEY_ID:-}" ]; then
    gpg --batch --yes --armor --detach-sign \
        --local-user "${ALX_GPG_KEY_ID}" \
        --output "${OUT_DIR}/SHA256SUMS.asc" \
        "${OUT_DIR}/SHA256SUMS"
    gpg --batch --yes --armor --detach-sign \
        --local-user "${ALX_GPG_KEY_ID}" \
        --output "${OUT_DIR}/${BASENAME}.asc" \
        "${ARTIFACT}"
    gpg --verify "${OUT_DIR}/SHA256SUMS.asc" "${OUT_DIR}/SHA256SUMS"
    echo "Signed and verified release artifacts with GPG key ${ALX_GPG_KEY_ID}."
else
    echo "NOTICE: ALX_GPG_KEY_ID not set; generated SHA256SUMS without GPG signature."
fi
