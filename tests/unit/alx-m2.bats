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

@test "alx-awesome and alx-dev package lists match v1.2 (SDDM, Awesome, Brave/VS Code hook, no Firefox)" {
    local desk="${ROOT_DIR}/config/package-lists/alx-awesome.list.chroot"
    local dev="${ROOT_DIR}/config/package-lists/alx-dev.list.chroot"
    local apps_hook="${ROOT_DIR}/config/hooks/live/0260-alx-apps.hook.chroot"
    [ -f "${desk}" ]
    [ -f "${dev}" ]
    [ -x "${apps_hook}" ]
    grep -qx "sddm" "${desk}"
    grep -qx "awesome" "${desk}"
    ! grep -qx "firefox-esr" "${dev}"
    grep -q "brave-browser" "${apps_hook}"
    grep -q " code$" "${apps_hook}"
    ! grep -Eq '^(lightdm|i3-wm|i3status|picom|snapd|docker\.io|docker-ce|flatpak)$' "${desk}"
}

@test "Awesome WM rc.lua has bottom dock, titlebars (min/max/close), and desktop icons" {
    local rc="${ROOT_DIR}/packages/alx-desktop-awesome/etc/skel/.config/awesome/rc.lua"
    [ -f "${rc}" ]
    grep -q 'position = "bottom"' "${rc}"
    grep -q 'request::titlebars' "${rc}"
    grep -q 'pcmanfm --desktop' "${rc}"
    grep -q 'gears.wallpaper' "${rc}"
    [ -f "${ROOT_DIR}/packages/alx-desktop-awesome/etc/skel/Desktop/alx-install.desktop" ]
    [ -f "${ROOT_DIR}/packages/alx-desktop-awesome/etc/skel/Desktop/alx-brave.desktop" ]
    [ -f "${ROOT_DIR}/packages/alx-desktop-awesome/etc/skel/Desktop/alx-vscode.desktop" ]
    ! grep -q 'vicious\|lain\|picom' "${rc}"
}

@test "SDDM theme alx, tokens.env, and Black Hole default PNG wallpapers exist" {
    local sddm_conf="${ROOT_DIR}/packages/alx-branding/etc/sddm.conf.d/alx.conf"
    local qml="${ROOT_DIR}/packages/alx-branding/usr/share/sddm/themes/alx/Main.qml"
    local tokens="${ROOT_DIR}/packages/alx-branding/usr/share/alx/theme/tokens.env"
    [ -f "${sddm_conf}" ]
    [ -f "${qml}" ]
    [ -f "${tokens}" ]
    grep -q '^DisplayServer=x11$' "${sddm_conf}"
    grep -q '^Current=alx$' "${sddm_conf}"
    for res in 1024x768 1280x720 1366x768 1920x1080; do
        [ -f "${ROOT_DIR}/packages/alx-branding/usr/share/backgrounds/alx/alx-${res}.png" ]
    done
}
