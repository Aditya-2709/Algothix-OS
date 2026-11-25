#!/usr/bin/env bats

ROOT_DIR="${BATS_TEST_DIRNAME}/../.."
ALX_SETUP="${ROOT_DIR}/packages/alx-setup/usr/bin/alx-setup"

setup() {
    TMP_TEST="$(mktemp -d)"
    printf 'alx-profile-low\n' > "${TMP_TEST}/profile_low"
    cat > "${TMP_TEST}/mock-apt" <<'EOF'
#!/usr/bin/env bash
printf 'MOCK_APT: %s\n' "$*"
EOF
    chmod +x "${TMP_TEST}/mock-apt"
}

teardown() {
    rm -rf "${TMP_TEST}"
}

@test "alx-setup supports --help, --version, list, and rejects unknown profiles" {
    run "${ALX_SETUP}" --help
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Usage: alx-setup"* ]]

    run "${ALX_SETUP}" --version
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"alx-setup 1.1.0"* ]]

    run "${ALX_SETUP}" list
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"python"* ]]
    [[ "${output}" == *"localsend"* ]]
    [[ "${output}" == *"kdeconnect"* ]]

    run "${ALX_SETUP}" nonexistent-lang
    [ "${status}" -eq 2 ]
}

@test "alx-setup python --dry-run prints disk/RAM cost and does not run apt" {
    run env ALX_APT_CMD="${TMP_TEST}/mock-apt" "${ALX_SETUP}" python --dry-run
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Expected disk cost"* ]]
    [[ "${output}" == *"Expected RAM usage"* ]]
    [[ "${output}" == *"[dry-run]"* ]]
    [[ "${output}" != *"MOCK_APT:"* ]]
}

@test "alx-setup python -y invokes apt update and install with verified packages" {
    run env ALX_APT_CMD="${TMP_TEST}/mock-apt" "${ALX_SETUP}" python -y
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"MOCK_APT: update"* ]]
    [[ "${output}" == *"MOCK_APT: install -y --no-install-recommends python3 python3-pip python3-venv python3-pytest"* ]]
}

@test "alx-setup localsend and kdeconnect --dry-run print costs, SHA-256, and caveats" {
    run env ALX_PROFILE_FILE="${TMP_TEST}/profile_low" "${ALX_SETUP}" localsend --dry-run
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"f2cc2d1f8a2542799576e4c1cc61ed1f35c6a7dba2f375870e8500eab6fbfe66"* ]]
    [[ "${output}" == *"WARNING:"* ]]

    run "${ALX_SETUP}" kdeconnect --dry-run
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"LAN only"* ]]
    [[ "${output}" == *"--no-install-recommends kdeconnect"* ]]
}
