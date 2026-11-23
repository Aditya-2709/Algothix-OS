#!/usr/bin/env bats

ROOT_DIR="${BATS_TEST_DIRNAME}/../.."

@test "alx-cheatsheet supports --help, --version, --stdout, and rejects unknown flags" {
    local bin="${ROOT_DIR}/packages/alx-desktop-i3/usr/bin/alx-cheatsheet"
    local sheet="${ROOT_DIR}/packages/alx-desktop-i3/usr/share/alx/cheatsheet.txt"
    [ -x "${bin}" ]

    run env ALX_CHEATSHEET_PATH="${sheet}" "${bin}" --help
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Usage: alx-cheatsheet"* ]]

    run env ALX_CHEATSHEET_PATH="${sheet}" "${bin}" --version
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"alx-cheatsheet 0.1.0"* ]]

    run env ALX_CHEATSHEET_PATH="${sheet}" "${bin}" --stdout
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"ALGOTHIX OS (ALX) LITE"* ]]

    run env ALX_CHEATSHEET_PATH="${sheet}" "${bin}" --unknown-flag
    [ "${status}" -eq 2 ]
}

@test "alx-i3 and alx-dev package lists respect PRD non-goals" {
    for list in \
        "${ROOT_DIR}/config/package-lists/alx-i3.list.chroot" \
        "${ROOT_DIR}/config/package-lists/alx-dev.list.chroot"; do
        [ -f "${list}" ]
        ! grep -Eq '^(snapd|docker\.io|docker-ce|flatpak|code|vscodium)$' "${list}"
    done
}

@test "ALX-i3 config has picom disabled by default and wires Super+? cheatsheet" {
    local i3cfg="${ROOT_DIR}/packages/alx-desktop-i3/etc/skel/.config/i3/config"
    [ -f "${i3cfg}" ]
    ! grep -Eq '^[[:space:]]*exec(_always)?[[:space:]].*picom' "${i3cfg}"
    grep -q 'alx-cheatsheet' "${i3cfg}"
    grep -q 'i3status' "${i3cfg}"
}

@test "Firefox ESR policy disables telemetry and enables low-RAM tab unloading" {
    local policy="${ROOT_DIR}/config/includes.chroot/etc/firefox-esr/policies/policies.json"
    [ -f "${policy}" ]
    python3 -m json.tool "${policy}" >/dev/null
    grep -q '"DisableTelemetry": true' "${policy}"
    grep -q '"browser.tabs.unloadOnLowMemory"' "${policy}"
}

@test "Dev defaults exist for Neovim, tmux, zsh, and rootless Podman" {
    [ -f "${ROOT_DIR}/config/includes.chroot/etc/skel/.config/nvim/init.lua" ]
    [ -f "${ROOT_DIR}/config/includes.chroot/etc/skel/.tmux.conf" ]
    [ -f "${ROOT_DIR}/config/includes.chroot/etc/skel/.zshrc" ]
    grep -q 'kernel.unprivileged_userns_clone = 1' \
        "${ROOT_DIR}/config/includes.chroot/etc/sysctl.d/90-alx-podman.conf"
    grep -q 'docker.io' \
        "${ROOT_DIR}/config/includes.chroot/etc/containers/registries.conf.d/10-alx-registries.conf"
}
