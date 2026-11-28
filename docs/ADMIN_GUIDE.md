# Algothix OS (ALX) Lite — Administrator Guide

Guide for team leads and system administrators managing 5–50 ALX Lite machines.

## 1. Multi-User Provisioning & Resource Isolation

Use `alx-adduser` to create local accounts with `/etc/skel` configs, `zsh`, and per-UID systemd cgroup memory limits:

```bash
sudo alx-adduser alice --admin
sudo alx-adduser intern1 --memory-max 1024
```

Per-user drop-ins are stored in `/etc/systemd/system/user-<uid>.slice.d/50-alx-limits.conf` and scale automatically to detected RAM so one user's build or browser tab spike cannot freeze another user's session.

## 2. Optional Central Directory (FreeIPA / LDAP via SSSD)

SSSD is not installed by default. To join an ALX laptop to a company directory:

```bash
sudo alx-join-domain --domain corp.example.com --server ldaps://ipa.corp.example.com --dry-run
sudo alx-join-domain --domain corp.example.com --server ldaps://ipa.corp.example.com
```

## 3. Fleet Management with Ansible

Edit `ansible/inventory.example.ini` and set `alx_users` / `alx_link_backend` in group/host vars, then run:

```bash
cd ansible
ansible-playbook -i inventory.example.ini site.yml
```

Roles applied idempotently:
- `base` — `APT::Install-Recommends "false"`, core packages, idempotent `alx-tune`
- `users` — Fleet user accounts and per-UID systemd slice limits
- `link` — `/etc/alx/link.conf` and low-priority Syncthing user drop-in
- `hardening` — UFW default-deny incoming, security-only `unattended-upgrades`, AppArmor

## 4. Internal APT Repository (`reprepro`)

`make packages` builds all `packages/alx-*` `.deb` files and publishes them to `build/repo/` using `reprepro`. Serve `build/repo/` over HTTPS and distribute your repository GPG public key via Ansible to push ALX updates across the fleet.

## 5. Security Baseline

- **Firewall:** `ufw` enabled with default-deny incoming (`DEFAULT_INPUT_POLICY="DROP"`).
- **Zero public listeners:** Fresh installs have no SSH server and zero externally listening ports (verify with `tests/qemu/security-test.sh` or `ss -tulpn`).
- **Updates:** `unattended-upgrades` applies Debian security updates daily; full upgrades are handled via `alx-update` (AC power + idle only).
- **MAC:** AppArmor enabled with Debian defaults.

## 6. Building & Signing Custom Releases

```bash
make docker-build
docker run --rm --privileged -v "$(pwd):/src" -w /src alx-builder:trixie \
  bash -lc "make packages && make lint && make test-unit && make iso && make test-qemu"
ALX_GPG_KEY_ID=<key-id> ./ci/release-sign.sh build/algothix-os-lite-amd64.iso build
```

## 7. Optional ALX Assistant — Licensing, Policy & Fleet Disablement

- **Testing Channel Only:** `alx-assistant` is published exclusively to the ALX APT `testing` channel via `.github/workflows/release-packages.yml` and is never included in ISO builds.
- **AGPL-3.0 Source Offer:** Every installed `.deb` includes `/usr/share/doc/alx-assistant/SOURCE`, `debian/copyright`, and `alx-assistant --source` pointing to `https://github.com/Aditya-2709/alx-assistant` (forked from `EricTechPro/jarvis` commit `af7465f`). *Disclaimer: This documentation is not legal advice; maintainers must review AGPL-3.0 compliance (including upstream's proprietary `@anthropic-ai/claude-agent-sdk` dependency) before promoting `alx-assistant` to `stable`.*
- **API Key Policy:** Never bake API keys into images, `/etc/skel`, or Ansible playbooks. Each user supplies their own key via `alx-assistant --setup` (stored per-user in GNOME Keyring / `0600` files).
- **Disabling Fleet-Wide:** Keep the `testing` APT suite disabled in `/etc/apt/sources.list.d/` or pin `alx-assistant` to priority `-1` via `/etc/apt/preferences.d/no-alx-assistant`:
  ```
  Package: alx-assistant
  Pin: release *
  Pin-Priority: -1
  ```
