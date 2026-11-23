#!/usr/bin/env bats

ROOT_DIR="${BATS_TEST_DIRNAME}/../.."
ALX_LINK="${ROOT_DIR}/packages/alx-link/usr/bin/alx-link"
ALX_CORE="${ROOT_DIR}/packages/alx-link/usr/lib/alx-link/alx-link-core.py"

setup() {
    TMP_TEST="$(mktemp -d)"
    mkdir -p "${TMP_TEST}/home_a" "${TMP_TEST}/home_b"
}

teardown() {
    rm -rf "${TMP_TEST}"
}

@test "alx-link supports --help, --version, and rejects unknown commands" {
    run "${ALX_LINK}" --help
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Usage: alx-link"* ]]

    run "${ALX_LINK}" --version
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"alx-link 0.1.0"* ]]

    run "${ALX_LINK}" bogus-cmd
    [ "${status}" -eq 2 ]
}

@test "alx-link pairs two peers over TCP with PIN, writes configs, and unpairs idempotently" {
    local port=47610
    HOME="${TMP_TEST}/home_a" ALX_LINK_HOSTNAME="alx-a" ALX_LINK_USER="alice" ALX_LINK_CORE="${ALX_CORE}" \
        "${ALX_LINK}" pair --listen --bind 127.0.0.1 --port "${port}" --code 123456 --timeout 15 >/dev/null 2>&1 &
    local pid=$!
    sleep 0.5

    run env HOME="${TMP_TEST}/home_b" ALX_LINK_HOSTNAME="alx-b" ALX_LINK_USER="bob" ALX_LINK_CORE="${ALX_CORE}" \
        "${ALX_LINK}" pair 127.0.0.1 --port "${port}" --code 123456
    [ "${status}" -eq 0 ]
    wait "${pid}"

    grep -q "Host alx-b" "${TMP_TEST}/home_a/.ssh/config.d/alx-link-alx-b.conf"
    grep -q "# alx-link:alx-b" "${TMP_TEST}/home_a/.ssh/authorized_keys"
    grep -q 'name="alx-b"' "${TMP_TEST}/home_a/.local/state/syncthing/config.xml"
    grep -q "alx-b:" "${TMP_TEST}/home_a/.config/alx-link/input-leap.conf"

    run env HOME="${TMP_TEST}/home_a" ALX_LINK_HOSTNAME="alx-a" ALX_LINK_CORE="${ALX_CORE}" \
        "${ALX_LINK}" status --json
    [ "${status}" -eq 0 ]
    printf '%s\n' "${output}" | python3 -m json.tool >/dev/null
    [[ "${output}" == *'"alx-b"'* ]]

    run env HOME="${TMP_TEST}/home_a" ALX_LINK_HOSTNAME="alx-a" ALX_LINK_CORE="${ALX_CORE}" \
        "${ALX_LINK}" unpair alx-b
    [ "${status}" -eq 0 ]
    [ ! -e "${TMP_TEST}/home_a/.ssh/config.d/alx-link-alx-b.conf" ]
    [ ! -e "${TMP_TEST}/home_a/.config/alx-link/input-leap.conf" ]

    # Second unpair is idempotent
    run env HOME="${TMP_TEST}/home_a" ALX_LINK_HOSTNAME="alx-a" ALX_LINK_CORE="${ALX_CORE}" \
        "${ALX_LINK}" unpair alx-b
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"already unpaired"* ]]
}

@test "alx-link rejects invalid pairing PIN" {
    local port=47611
    HOME="${TMP_TEST}/home_a" ALX_LINK_HOSTNAME="alx-a" ALX_LINK_USER="alice" ALX_LINK_CORE="${ALX_CORE}" \
        "${ALX_LINK}" pair --listen --bind 127.0.0.1 --port "${port}" --code 222222 --timeout 10 >/dev/null 2>&1 &
    local pid=$!
    sleep 0.5

    run env HOME="${TMP_TEST}/home_b" ALX_LINK_HOSTNAME="alx-b" ALX_LINK_USER="bob" ALX_LINK_CORE="${ALX_CORE}" \
        "${ALX_LINK}" pair 127.0.0.1 --port "${port}" --code 999999
    [ "${status}" -eq 1 ]
    wait "${pid}" || true
}
