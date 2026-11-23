#!/usr/bin/env bats

ROOT_DIR="${BATS_TEST_DIRNAME}/../.."
LAUNCHER="${ROOT_DIR}/packages/alx-installer-config/usr/sbin/alx-calamares-launch"
WELCOME="${ROOT_DIR}/packages/alx-branding/usr/bin/alx-welcome"
SRC_CAL="${ROOT_DIR}/packages/alx-installer-config/usr/share/alx/calamares"

setup() {
    TMP_TEST="$(mktemp -d)"
    printf 'flags\t\t: fpu vme de pse\n' > "${TMP_TEST}/cpu_no_aes"
    printf 'flags\t\t: fpu vme de pse aes\n' > "${TMP_TEST}/cpu_aes"
}

teardown() {
    rm -rf "${TMP_TEST}"
}

@test "alx-calamares-launch disables LUKS when CPU lacks AES-NI (FR-6.2)" {
    run env \
        ALX_CALAMARES_SRC="${SRC_CAL}" \
        ALX_CALAMARES_RUNTIME="${TMP_TEST}/run_no_aes" \
        ALX_PROC_CPUINFO="${TMP_TEST}/cpu_no_aes" \
        "${LAUNCHER}" --dry-run
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"LUKS disk encryption DISABLED"* ]]
    grep -q '^enableLuksAutomatedPartitioning: false$' "${TMP_TEST}/run_no_aes/modules/partition.conf"
    grep -q 'defaultFileSystemType: "ext4"' "${TMP_TEST}/run_no_aes/modules/partition.conf"
}

@test "alx-calamares-launch enables LUKS when CPU has AES-NI (FR-6.2)" {
    run env \
        ALX_CALAMARES_SRC="${SRC_CAL}" \
        ALX_CALAMARES_RUNTIME="${TMP_TEST}/run_aes" \
        ALX_PROC_CPUINFO="${TMP_TEST}/cpu_aes" \
        "${LAUNCHER}" --dry-run
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"LUKS disk encryption option ENABLED"* ]]
    grep -q '^enableLuksAutomatedPartitioning: true$' "${TMP_TEST}/run_aes/modules/partition.conf"
}

@test "alx-branding Calamares assets and first-boot welcome work" {
    [ -f "${ROOT_DIR}/packages/alx-branding/usr/share/alx/logo.svg" ]
    [ -f "${ROOT_DIR}/packages/alx-branding/usr/share/alx/calamares/branding/alx/branding.desc" ]
    [ -f "${ROOT_DIR}/packages/alx-branding/usr/share/alx/calamares/branding/alx/show.qml" ]

    run "${WELCOME}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"alx-setup"* ]]
    [[ "${output}" == *"alx-link"* ]]
    [[ "${output}" == *"alx-doctor"* ]]
}
