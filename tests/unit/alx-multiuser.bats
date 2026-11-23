#!/usr/bin/env bats

ROOT_DIR="${BATS_TEST_DIRNAME}/../.."
ADDUSER="${ROOT_DIR}/packages/alx-base/usr/sbin/alx-adduser"
JOIN_DOMAIN="${ROOT_DIR}/packages/alx-base/usr/sbin/alx-join-domain"

setup() {
    TMP_TEST="$(mktemp -d)"
    printf 'MemTotal:        2097152 kB\n' > "${TMP_TEST}/mem_2g"
}

teardown() {
    rm -rf "${TMP_TEST}"
}

@test "alx-adduser writes per-user systemd slice drop-in and validates usernames" {
    run "${ADDUSER}" --help
    [ "${status}" -eq 0 ]

    run "${ADDUSER}" "BAD USER!" --dry-run
    [ "${status}" -eq 2 ]

    run env ALX_PROC_MEMINFO="${TMP_TEST}/mem_2g" ALX_TEST_UID=1005 \
        "${ADDUSER}" alice --root "${TMP_TEST}/root"
    [ "${status}" -eq 0 ]
    grep -q 'MemoryMax=1228M' "${TMP_TEST}/root/etc/systemd/system/user-1005.slice.d/50-alx-limits.conf"
}

@test "alx-join-domain generates 0600 sssd.conf with derived base DN" {
    run "${JOIN_DOMAIN}" --help
    [ "${status}" -eq 0 ]

    run "${JOIN_DOMAIN}" --domain corp.example.com --server ldaps://ipa.corp.example.com --root "${TMP_TEST}/root"
    [ "${status}" -eq 0 ]
    grep -q 'ldap_search_base = dc=corp,dc=example,dc=com' "${TMP_TEST}/root/etc/sssd/sssd.conf"
    [ "$(stat -c %a "${TMP_TEST}/root/etc/sssd/sssd.conf")" = "600" ]
}

@test "security hardening hook and Ansible fleet roles exist" {
    [ -x "${ROOT_DIR}/config/hooks/live/0400-alx-hardening.hook.chroot" ]
    [ -f "${ROOT_DIR}/ansible/site.yml" ]
    [ -f "${ROOT_DIR}/ansible/roles/base/tasks/main.yml" ]
    [ -f "${ROOT_DIR}/ansible/roles/users/tasks/main.yml" ]
    [ -f "${ROOT_DIR}/ansible/roles/link/tasks/main.yml" ]
    [ -f "${ROOT_DIR}/ansible/roles/hardening/tasks/main.yml" ]
}
