#!/usr/bin/env bats

ROOT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"

@test "alx-assistant is never preinstalled in any ISO package list" {
    ! grep -rn "alx-assistant" "${ROOT_DIR}/config/package-lists/"
}

@test "ci/build-packages.sh excludes alx-assistant from ISO build/debs and targets testing" {
    grep -q 'pkg_name.*alx-assistant' "${ROOT_DIR}/ci/build-packages.sh"
    grep -q 'includedeb testing' "${ROOT_DIR}/ci/build-packages.sh"
}

@test "packages/alx-assistant contains no API key-like strings" {
    ! grep -rnE '(AIza[0-9A-Za-z_-]{20,}|sk-ant-[0-9A-Za-z_-]{10,}|sk-proj-[0-9A-Za-z_-]{10,}|sk-[0-9A-Za-z]{20,})' \
        "${ROOT_DIR}/packages/alx-assistant/"
}

@test "alx-assistant --source prints AGPL-3.0 fork URL and pinned upstream commit" {
    run "${ROOT_DIR}/packages/alx-assistant/usr/bin/alx-assistant" --source
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"AGPL-3.0"* ]]
    [[ "${output}" == *"af7465f"* ]]
    [[ "${output}" == *"alx-assistant"* ]]
}

@test "alx-setup assistant --dry-run warns on internet, API key, low profile, and outbound-only" {
    tmp_prof="$(mktemp)"
    echo "alx-profile-low" > "${tmp_prof}"
    run env ALX_PROFILE_FILE="${tmp_prof}" "${ROOT_DIR}/packages/alx-setup/usr/bin/alx-setup" assistant --dry-run
    rm -f "${tmp_prof}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"REQUIRES internet"* ]]
    [[ "${output}" == *"NOT recommended on alx-profile-low"* ]]
    [[ "${output}" == *"no inbound ufw ports opened"* ]]
}

@test "alx-setup assistant --remove --dry-run preserves user data" {
    run "${ROOT_DIR}/packages/alx-setup/usr/bin/alx-setup" assistant --remove --dry-run
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"purge -y alx-assistant"* ]]
    [[ "${output}" == *"preserved"* ]]
}

@test "alx-assistant enforces safe defaults and 0600 permissions" {
    grep -q '"allowActions": false' "${ROOT_DIR}/packages/alx-assistant/usr/bin/alx-assistant"
    grep -q '"skipAllow": false' "${ROOT_DIR}/packages/alx-assistant/usr/bin/alx-assistant"
    grep -q '"rawReadOnly": true' "${ROOT_DIR}/packages/alx-assistant/usr/bin/alx-assistant"
    grep -q '"telemetry": false' "${ROOT_DIR}/packages/alx-assistant/usr/bin/alx-assistant"
    grep -q 'chmod 600' "${ROOT_DIR}/packages/alx-assistant/usr/bin/alx-assistant"
    grep -q '0o600' "${ROOT_DIR}/packages/alx-assistant/usr/bin/alx-assistant-setup"
}

@test "Awesome WM rc.lua integrates ALX Assistant with >=2s polling and conflict-free hotkeys" {
    local rc="${ROOT_DIR}/packages/alx-desktop-awesome/etc/skel/.config/awesome/rc.lua"
    grep -q 'assistant_widget' "${rc}"
    grep -q 'timeout = 5' "${rc}"
    grep -q 'alx-assistant --panic-stop' "${rc}"
    ! grep -q 'vicious\|lain\|picom' "${rc}"
}
