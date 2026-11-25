#!/usr/bin/env bats

ROOT_DIR="${BATS_TEST_DIRNAME}/../.."
ALX_TUNE="${ROOT_DIR}/packages/alx-tune/usr/sbin/alx-tune"
ALX_DOCTOR="${ROOT_DIR}/packages/alx-doctor/usr/bin/alx-doctor"

setup() {
    TMP_TEST="$(mktemp -d)"
    printf 'MemTotal:        2097152 kB\nMemAvailable:    1638400 kB\n' > "${TMP_TEST}/mem_2g"
    printf 'flags\t\t: fpu vme de pse tsc msr pae\n' > "${TMP_TEST}/cpu_no_aes"
    printf 'Filename\tType\tSize\tUsed\tPriority\n/dev/zram0\tpartition\t1048576\t0\t100\n' > "${TMP_TEST}/swaps_zram"
    printf 'Filename\tType\tSize\tUsed\tPriority\n' > "${TMP_TEST}/swaps_empty"
    mkdir -p "${TMP_TEST}/root/etc/udev/rules.d"
    cp "${ROOT_DIR}/packages/alx-tune/usr/lib/udev/rules.d/60-alx-io-scheduler.rules" \
        "${TMP_TEST}/root/etc/udev/rules.d/"
}

teardown() {
    rm -rf "${TMP_TEST}"
}

@test "alx-doctor supports --help, --version, and rejects unknown options" {
    run "${ALX_DOCTOR}" --help
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Usage: alx-doctor"* ]]

    run "${ALX_DOCTOR}" --version
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"alx-doctor 0.1.0"* ]]

    run "${ALX_DOCTOR}" --unknown
    [ "${status}" -eq 2 ]
}

@test "alx-doctor returns FAIL (exit 1) on untuned root" {
    run env \
        ALX_PROC_MEMINFO="${TMP_TEST}/mem_2g" \
        ALX_PROC_SWAPS="${TMP_TEST}/swaps_empty" \
        "${ALX_DOCTOR}" --root "${TMP_TEST}/untuned"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"FAIL"* ]]
}

@test "alx-doctor returns OK (exit 0) and valid --json on tuned 2 GB root" {
    ALX_PROC_MEMINFO="${TMP_TEST}/mem_2g" \
    ALX_PROC_CPUINFO="${TMP_TEST}/cpu_no_aes" \
        "${ALX_TUNE}" --root "${TMP_TEST}/root" >/dev/null

    run env \
        ALX_PROC_MEMINFO="${TMP_TEST}/mem_2g" \
        ALX_PROC_SWAPS="${TMP_TEST}/swaps_zram" \
        "${ALX_DOCTOR}" --root "${TMP_TEST}/root"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Overall status: OK"* ]]

    run env \
        ALX_PROC_MEMINFO="${TMP_TEST}/mem_2g" \
        ALX_PROC_SWAPS="${TMP_TEST}/swaps_zram" \
        "${ALX_DOCTOR}" --root "${TMP_TEST}/root" --json
    [ "${status}" -eq 0 ]
    printf '%s\n' "${output}" | python3 -m json.tool >/dev/null
    [[ "${output}" == *'"status": "OK"'* ]]
    [[ "${output}" == *'"fail_count": 0'* ]]
}
