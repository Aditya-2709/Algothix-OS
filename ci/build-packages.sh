#!/usr/bin/env bash
set -euo pipefail

# Build all Debian packages under packages/*/debian and publish them to build/repo.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build"
DEBS_DIR="${BUILD_DIR}/debs"
REPO_DIR="${BUILD_DIR}/repo"
DIST_CODENAME="${ALX_DEBIAN_DIST:-trixie}"

mkdir -p "${DEBS_DIR}" "${REPO_DIR}/conf"

cat > "${REPO_DIR}/conf/distributions" <<EOF
Origin: Algothix
Label: Algothix OS
Codename: ${DIST_CODENAME}
Architectures: amd64
Components: main
Description: Local Algothix OS (ALX) APT repository
EOF

built_count=0

for pkg_dir in "${ROOT_DIR}"/packages/*; do
    [ -d "${pkg_dir}/debian" ] || continue
    pkg_name="$(basename "${pkg_dir}")"
    echo "==> Building package: ${pkg_name}"

    if command -v dpkg-buildpackage >/dev/null 2>&1 && command -v dh >/dev/null 2>&1; then
        (
            cd "${pkg_dir}"
            dpkg-buildpackage -us -uc -b
        )
        # dpkg-buildpackage outputs .deb files to the parent directory (packages/)
        for deb in "${ROOT_DIR}"/packages/"${pkg_name}"_*.deb; do
            [ -f "${deb}" ] || continue
            mv -f "${deb}" "${DEBS_DIR}/"
        done
        rm -f "${ROOT_DIR}"/packages/"${pkg_name}"_*.buildinfo \
              "${ROOT_DIR}"/packages/"${pkg_name}"_*.changes
        built_count=$((built_count + 1))
    else
        echo "ERROR: dpkg-buildpackage and debhelper (dh) are required to build ${pkg_name}." >&2
        exit 1
    fi
done

if [ "${built_count}" -eq 0 ]; then
    echo "No Debian packages with a debian/ directory found to build."
    exit 0
fi

if command -v reprepro >/dev/null 2>&1; then
    echo "==> Publishing ${built_count} package(s) to local reprepro repository (${REPO_DIR})"
    for deb in "${DEBS_DIR}"/*.deb; do
        [ -f "${deb}" ] || continue
        reprepro -b "${REPO_DIR}" includedeb "${DIST_CODENAME}" "${deb}"
    done
else
    echo "WARNING: reprepro not found; .deb files are in ${DEBS_DIR} but local apt repo metadata was not generated." >&2
fi

echo "==> Package build complete: ${built_count} package(s) in ${DEBS_DIR}"
