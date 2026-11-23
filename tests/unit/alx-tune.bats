#!/usr/bin/env bats

ROOT_DIR="${BATS_TEST_DIRNAME}/../.."
ALX_TUNE="${ROOT_DIR}/packages/alx-tune/usr/sbin/alx-tune"

setup() {
    TMP_TEST="$(mktemp -d)"
    printf 'MemTotal:        2097152 kB\n' > "${TMP_TEST}/mem_2g"
    printf 'MemTotal:        4194304 kB\n' > "${TMP_TEST}/mem_4g"
    printf 'flags\t\t: fpu vme de pse tsc msr pae\n' > "${TMP_TEST}/cpu_no_aes"
    printf 'flags\t\t: fpu vme de pse tsc msr pae aes\n' > "${TMP_TEST}/cpu_aes"
    mkdir -p "${TMP_TEST}/sysblock/sda/queue"
    printf '1\n' > "${TMP_TEST}/sysblock/sda/queue/rotational"
}

teardown() {
    rm -rf "${TMP_TEST}"
}

@test "alx-tune supports --help, --version, and rejects invalid arguments" {
    run "${ALX_TUNE}" --help
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Usage: alx-tune"* ]]

    run "${ALX_TUNE}" --version
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"alx-tune 0.1.0"* ]]

    run "${ALX_TUNE}" --profile invalid-profile --root "${TMP_TEST}/r0"
    [ "${status}" -eq 2 ]
}

@test "alx-tune selects alx-profile-low on 2 GB RAM and is idempotent on second run" {
    run env \
        ALX_PROC_MEMINFO="${TMP_TEST}/mem_2g" \
        ALX_PROC_CPUINFO="${TMP_TEST}/cpu_no_aes" \
        ALX_SYS_BLOCK="${TMP_TEST}/sysblock" \
        "${ALX_TUNE}" --root "${TMP_TEST}/r1"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Changes applied: 6"* ]]
    [ "$(cat "${TMP_TEST}/r1/etc/alx/profile")" = "alx-profile-low" ]
    grep -q '^ALGO=zstd' "${TMP_TEST}/r1/etc/default/zramswap"
    grep -q '^PERCENT=50' "${TMP_TEST}/r1/etc/default/zramswap"
    grep -q 'MemoryMax=1536M' "${TMP_TEST}/r1/etc/systemd/system/user-.slice.d/50-alx-limits.conf"

    # Second run must make zero changes (M3 AC)
    run env \
        ALX_PROC_MEMINFO="${TMP_TEST}/mem_2g" \
        ALX_PROC_CPUINFO="${TMP_TEST}/cpu_no_aes" \
        ALX_SYS_BLOCK="${TMP_TEST}/sysblock" \
        "${ALX_TUNE}" --root "${TMP_TEST}/r1"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Changes applied: 0"* ]]
}

@test "alx-tune selects alx-profile-mid on 4 GB RAM with AES-NI" {
    run env \
        ALX_PROC_MEMINFO="${TMP_TEST}/mem_4g" \
        ALX_PROC_CPUINFO="${TMP_TEST}/cpu_aes" \
        ALX_SYS_BLOCK="${TMP_TEST}/sysblock" \
        "${ALX_TUNE}" --root "${TMP_TEST}/r2"
    [ "${status}" -eq 0 ]
    [ "$(cat "${TMP_TEST}/r2/etc/alx/profile")" = "alx-profile-mid" ]
    grep -q 'TasksMax=1024' "${TMP_TEST}/r2/etc/systemd/system/user-.slice.d/50-alx-limits.conf"
}

@test "alx-tune --dry-run reports changes without writing files" {
    run env \
        ALX_PROC_MEMINFO="${TMP_TEST}/mem_2g" \
        ALX_PROC_CPUINFO="${TMP_TEST}/cpu_no_aes" \
        "${ALX_TUNE}" --dry-run --root "${TMP_TEST}/r3"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"[dry-run]"* ]]
    [ ! -e "${TMP_TEST}/r3/etc/alx/profile" ]
}
