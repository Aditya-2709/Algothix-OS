#!/usr/bin/env bats

ROOT_DIR="${BATS_TEST_DIRNAME}/../.."
ALX_UPDATE="${ROOT_DIR}/packages/alx-update/usr/sbin/alx-update"

setup() {
    TMP_TEST="$(mktemp -d)"
    mkdir -p "${TMP_TEST}/power_ac/AC0" "${TMP_TEST}/power_bat/AC0"
    printf 'Mains\n' > "${TMP_TEST}/power_ac/AC0/type"
    printf '1\n' > "${TMP_TEST}/power_ac/AC0/online"
    printf 'Mains\n' > "${TMP_TEST}/power_bat/AC0/type"
    printf '0\n' > "${TMP_TEST}/power_bat/AC0/online"

    printf '0.15 0.10 0.05 1/120 1234\n' > "${TMP_TEST}/load_idle"
    printf '3.80 3.50 3.10 4/200 1234\n' > "${TMP_TEST}/load_busy"

    cat > "${TMP_TEST}/mock-apt" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "update" ]; then
    exit 0
fi
printf '2 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.\n'
EOF
    chmod +x "${TMP_TEST}/mock-apt"
}

teardown() {
    rm -rf "${TMP_TEST}"
}

@test "alx-update supports --help, --version, and rejects unknown options" {
    run "${ALX_UPDATE}" --help
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Usage: alx-update"* ]]

    run "${ALX_UPDATE}" --version
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"alx-update 0.1.0"* ]]

    run "${ALX_UPDATE}" --bogus
    [ "${status}" -eq 2 ]
}

@test "alx-update skips cleanly on battery and when CPU load is high" {
    run env \
        ALX_POWER_DIR="${TMP_TEST}/power_bat" \
        ALX_PROC_LOADAVG="${TMP_TEST}/load_idle" \
        ALX_CPU_COUNT=2 \
        ALX_APT_CMD="${TMP_TEST}/mock-apt" \
        "${ALX_UPDATE}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"running on battery"* ]]

    run env \
        ALX_POWER_DIR="${TMP_TEST}/power_ac" \
        ALX_PROC_LOADAVG="${TMP_TEST}/load_busy" \
        ALX_CPU_COUNT=2 \
        ALX_APT_CMD="${TMP_TEST}/mock-apt" \
        "${ALX_UPDATE}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"system load is high"* ]]
}

@test "alx-update runs and prints summary on AC power when idle (and with --force)" {
    run env \
        ALX_POWER_DIR="${TMP_TEST}/power_ac" \
        ALX_PROC_LOADAVG="${TMP_TEST}/load_idle" \
        ALX_CPU_COUNT=2 \
        ALX_APT_CMD="${TMP_TEST}/mock-apt" \
        ALX_REBOOT_FLAG="${TMP_TEST}/no-reboot" \
        "${ALX_UPDATE}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"ALX Update summary: 2 upgraded, 0 newly installed"* ]]

    run env \
        ALX_POWER_DIR="${TMP_TEST}/power_bat" \
        ALX_PROC_LOADAVG="${TMP_TEST}/load_busy" \
        ALX_CPU_COUNT=2 \
        ALX_APT_CMD="${TMP_TEST}/mock-apt" \
        ALX_REBOOT_FLAG="${TMP_TEST}/no-reboot" \
        "${ALX_UPDATE}" --force
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"ALX Update summary: 2 upgraded"* ]]
}
