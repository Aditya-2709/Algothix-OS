#!/usr/bin/env bash
set -euo pipefail

# Build Debian packages under packages/*/debian and publish them to build/repo.
# IMPORTANT: alx-assistant is NEVER included in build/debs/ (which feeds the ISO).
# Set ALX_BUILD_OPTIONAL_ASSISTANT=1 to build alx-assistant into build/optional-debs/
# and publish it ONLY to the APT 'testing' channel.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build"
DEBS_DIR="${BUILD_DIR}/debs"
OPT_DEBS_DIR="${BUILD_DIR}/optional-debs"
REPO_DIR="${BUILD_DIR}/repo"
DIST_CODENAME="${ALX_DEBIAN_DIST:-trixie}"
BUILD_ASSISTANT="${ALX_BUILD_OPTIONAL_ASSISTANT:-0}"

rm -rf "${REPO_DIR}" && mkdir -p "${DEBS_DIR}" "${OPT_DEBS_DIR}" "${REPO_DIR}/conf"

cat > "${REPO_DIR}/conf/distributions" <<EOF
Origin: Algothix
Label: Algothix OS
Codename: ${DIST_CODENAME}
Architectures: amd64
Components: main
Description: Local Algothix OS (ALX) APT repository

Origin: Algothix
Label: Algothix OS Testing
Codename: testing
Architectures: amd64
Components: main
Description: Algothix OS (ALX) optional testing channel (not preinstalled on ISO)
EOF

built_count=0
opt_count=0

for pkg_dir in "${ROOT_DIR}"/packages/*; do
    [ -d "${pkg_dir}/debian" ] || continue
    pkg_name="$(basename "${pkg_dir}")"

    if [ "${pkg_name}" = "alx-assistant" ] && [ "${BUILD_ASSISTANT}" -ne 1 ]; then
        echo "==> Skipping optional testing package '${pkg_name}' (set ALX_BUILD_OPTIONAL_ASSISTANT=1 to build)"
        continue
    fi

    echo "==> Building package: ${pkg_name}"

    if command -v dpkg-buildpackage >/dev/null 2>&1 && command -v dh >/dev/null 2>&1; then
        (
            cd "${pkg_dir}"
            dpkg-buildpackage -us -uc -b
        )
        target_dir="${DEBS_DIR}"
        if [ "${pkg_name}" = "alx-assistant" ]; then
            target_dir="${OPT_DEBS_DIR}"
        fi
        for deb in "${ROOT_DIR}"/packages/"${pkg_name}"_*.deb; do
            [ -f "${deb}" ] || continue
            mv -f "${deb}" "${target_dir}/"
        done
        rm -f "${ROOT_DIR}"/packages/"${pkg_name}"_*.buildinfo \
              "${ROOT_DIR}"/packages/"${pkg_name}"_*.changes
        if [ "${pkg_name}" = "alx-assistant" ]; then
            opt_count=$((opt_count + 1))
        else
            built_count=$((built_count + 1))
        fi
    else
        echo "ERROR: dpkg-buildpackage and debhelper (dh) are required to build ${pkg_name}." >&2
        exit 1
    fi
done

if [ "${built_count}" -eq 0 ] && [ "${opt_count}" -eq 0 ]; then
    echo "No Debian packages with a debian/ directory found to build."
    exit 0
fi

if command -v reprepro >/dev/null 2>&1; then
    echo "==> Publishing ${built_count} core package(s) to '${DIST_CODENAME}' (${REPO_DIR})"
    for deb in "${DEBS_DIR}"/*.deb; do
        [ -f "${deb}" ] || continue
        reprepro -b "${REPO_DIR}" includedeb "${DIST_CODENAME}" "${deb}"
    done
    if [ "${opt_count}" -gt 0 ]; then
        echo "==> Publishing ${opt_count} optional package(s) to 'testing' channel ONLY"
        for deb in "${OPT_DEBS_DIR}"/*.deb; do
            [ -f "${deb}" ] || continue
            reprepro -b "${REPO_DIR}" includedeb testing "${deb}"
        done
    fi
else
    echo "WARNING: reprepro not found; .deb files built but local apt repo metadata was not generated." >&2
fi

echo "==> Package build complete: ${built_count} core in ${DEBS_DIR}, ${opt_count} optional in ${OPT_DEBS_DIR}"
