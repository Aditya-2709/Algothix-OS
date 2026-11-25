#!/usr/bin/env bats

ROOT_DIR="${BATS_TEST_DIRNAME}/../.."

@test "alx-cheatsheet supports --help, --version, --stdout, and rejects unknown flags" {
    local bin="${ROOT_DIR}/packages/alx-desktop-awesome/usr/bin/alx-cheatsheet"
    local sheet="${ROOT_DIR}/packages/alx-desktop-awesome/usr/share/alx/cheatsheet.txt"
    [ -x "${bin}" ]

    run env ALX_CHEATSHEET_PATH="${sheet}" "${bin}" --help
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Usage: alx-cheatsheet"* ]]

    run env ALX_CHEATSHEET_PATH="${sheet}" "${bin}" --version
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"alx-cheatsheet 1.1.0"* ]]

    run env ALX_CHEATSHEET_PATH="${sheet}" "${bin}" --stdout
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"AWESOME WM KEYBINDINGS"* ]]

    run env ALX_CHEATSHEET_PATH="${sheet}" "${bin}" --unknown-flag
    [ "${status}" -eq 2 ]
}

@test "alx-awesome and alx-dev package lists respect PRD non-goals and CHANGE-001" {
    local desk="${ROOT_DIR}/config/package-lists/alx-awesome.list.chroot"
    local dev="${ROOT_DIR}/config/package-lists/alx-dev.list.chroot"
    [ -f "${desk}" ]
    [ -f "${dev}" ]
    grep -qx "sddm" "${desk}"
    grep -qx "awesome" "${desk}"
    grep -qx "libnotify-bin" "${desk}"
    ! grep -Eq '^(lightdm|i3-wm|i3status|picom|snapd|docker\.io|docker-ce|flatpak|code|vscodium)$' "${desk}"
    ! grep -Eq '^(snapd|docker\.io|docker-ce|flatpak|code|vscodium|input-leap|croc|kdeconnect)$' "${dev}"
}

@test "Awesome WM rc.lua uses built-ins, 5 tags, 28px wibar, and PNG wallpapers" {
    local rc="${ROOT_DIR}/packages/alx-desktop-awesome/etc/skel/.config/awesome/rc.lua"
    [ -f "${rc}" ]
    grep -q 'height = 28' "${rc}"
    grep -q 'gears.wallpaper' "${rc}"
    grep -q '"1:term", "2:code", "3:web", "4:ops", "5:misc"' "${rc}"
    grep -q 'alx-cheatsheet' "${rc}"
    ! grep -q 'vicious\|lain\|picom' "${rc}"
}

@test "SDDM theme alx and 4 PNG ASCII wallpapers exist with X11-only config" {
    local sddm_conf="${ROOT_DIR}/packages/alx-branding/etc/sddm.conf.d/alx.conf"
    local qml="${ROOT_DIR}/packages/alx-branding/usr/share/sddm/themes/alx/Main.qml"
    [ -f "${sddm_conf}" ]
    [ -f "${qml}" ]
    grep -q '^DisplayServer=x11$' "${sddm_conf}"
    grep -q '^Current=alx$' "${sddm_conf}"
    grep -q '#0B0D10' "${qml}"
    grep -q '#3DDC97' "${qml}"
    for res in 1024x768 1280x720 1366x768 1920x1080; do
        [ -f "${ROOT_DIR}/packages/alx-branding/usr/share/alx/wallpapers/alx-${res}.png" ]
    done
}

@test "Firefox ESR policy disables telemetry and enables low-RAM tab unloading" {
    local policy="${ROOT_DIR}/config/includes.chroot/etc/firefox-esr/policies/policies.json"
    [ -f "${policy}" ]
    python3 -m json.tool "${policy}" >/dev/null
    grep -q '"DisableTelemetry": true' "${policy}"
    grep -q '"browser.tabs.unloadOnLowMemory"' "${policy}"
}
