#!/usr/bin/env bats

ROOT_DIR="${BATS_TEST_DIRNAME}/../.."

@test "alx-base.list.chroot includes core PRD packages and non-free-firmware" {
    local pkg_list="${ROOT_DIR}/config/package-lists/alx-base.list.chroot"
    [ -f "${pkg_list}" ]
    grep -qx "systemd" "${pkg_list}"
    grep -qx "network-manager" "${pkg_list}"
    grep -qx "zram-tools" "${pkg_list}"
    grep -qx "earlyoom" "${pkg_list}"
    grep -qx "ufw" "${pkg_list}"
    grep -qx "unattended-upgrades" "${pkg_list}"
    grep -qx "apparmor" "${pkg_list}"
    grep -qx "linux-image-amd64" "${pkg_list}"
    grep -qx "firmware-linux-free" "${pkg_list}"
    grep -qx "firmware-iwlwifi" "${pkg_list}"
}

@test "alx-base.list.chroot respects PRD non-goals (no snap, docker, flatpak, heavy IDEs)" {
    local pkg_list="${ROOT_DIR}/config/package-lists/alx-base.list.chroot"
    ! grep -Eq '^(snapd|docker\.io|docker-ce|flatpak|code|vscodium)$' "${pkg_list}"
}

@test "alx-base disables APT recommended packages by default (FR-1.1)" {
    local apt_cfg="${ROOT_DIR}/packages/alx-base/etc/apt/apt.conf.d/90alx-no-recommends"
    [ -f "${apt_cfg}" ]
    grep -q 'APT::Install-Recommends "false";' "${apt_cfg}"
}

@test "os-release hook configures Algothix OS identity and hostname alx" {
    local hook="${ROOT_DIR}/config/hooks/live/0100-alx-os-release.hook.chroot"
    [ -x "${hook}" ]
    grep -q 'NAME="Algothix OS"' "${hook}"
    grep -q 'ID=alx' "${hook}"
    grep -q 'ID_LIKE=debian' "${hook}"
    grep -q "printf 'alx\\\\n' > /etc/hostname" "${hook}"
}

@test "bootloaders are branded for Algothix OS with nomodeset fallback" {
    grep -q "Algothix OS" "${ROOT_DIR}/config/bootloaders/isolinux/menu.cfg"
    grep -q "nomodeset" "${ROOT_DIR}/config/bootloaders/isolinux/live.cfg.in"
    grep -q "Algothix OS" "${ROOT_DIR}/config/bootloaders/grub-efi/grub.cfg"
    grep -q "nomodeset" "${ROOT_DIR}/config/bootloaders/grub-efi/grub.cfg"
}
