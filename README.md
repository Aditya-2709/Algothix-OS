# Algothix OS (ALX) Lite

A fast, lightweight, Debian 13 (`trixie`) Linux distribution for programming and multitasking on old hardware (2–4 GB RAM, 64-bit x86_64 CPU, HDD).

## Status

- **Version:** 1.1 (`CHANGE-001`: X11-only SDDM + Awesome WM + Lightweight ALX Link)
- **Base:** Debian 13 (`trixie`, amd64) with `main` and `non-free-firmware`
- **License:** GPL-3.0-or-later (see `LICENSE`)

## Documentation

- [User Guide](docs/USER_GUIDE.md) — Installing, Awesome WM keybindings, `alx-setup`, `alx-link`, `alx-doctor`, `alx-update`
- [Admin Guide](docs/ADMIN_GUIDE.md) — Multi-user isolation, optional SSSD, Ansible fleet roles, `reprepro` repo, security baseline
- [Change Log (CHANGE-001)](docs/CHANGE-001.md) — SDDM, Awesome WM, and ALX Link rewrite plan
- [Engineering Decisions](docs/DECISIONS.md) — Recorded PRD defaults, trade-offs, and rejected alternatives
- [ALX Assistant Evaluation](docs/ASSISTANT-EVALUATION.md) — Upstream `EricTechPro/jarvis` audit, Debian `trixie`/X11 readiness, and QEMU benchmarks
- [ALX Agent CLI Design](docs/ASSISTANT-CLI-DESIGN.md) — Lightweight 15–35 MB terminal agent design for `alx-profile-low`
- [Third-Party Packages](docs/THIRD_PARTY.md) — Tailscale apt repo and pinned LocalSend v1.19.0 SHA-256
- [Physical Hardware Test Checklist](tests/hardware/HARDWARE_TEST.md) — Dell Vostro 1015 & ASUS X541NA validation

## Repository Layout

- `auto/` — `live-build` entry scripts (`config`, `build`, `clean`)
- `config/` — `live-build` package lists (`alx-base`, `alx-awesome`, `alx-dev`, `alx-installer`), Tailscale apt archive, chroot hooks, includes, and BIOS/UEFI bootloader branding
- `packages/` — Debian source packages (`alx-base`, `alx-desktop-awesome`, `alx-tune`, `alx-doctor`, `alx-setup`, `alx-update`, `alx-link`, `alx-branding`, `alx-installer-config`)
- `ansible/` — Fleet management playbook (`site.yml`) and roles (`base`, `users`, `link`, `hardening`)
- `tests/` — Unit (`bats`), QEMU smoke/link/install/multi-user/security tests, and physical hardware checklist
- `ci/` — Build, lint, Tailscale key fetch, environment setup, and GPG release signing scripts
- `.github/workflows/` — CI (`ci.yml`), nightly budget enforcement (`nightly.yml`), and tagged releases (`release.yml`)

## Quick Start

```bash
make docker-build
docker run --rm --privileged -v "$(pwd):/src" alx-builder:trixie \
  bash -lc 'mkdir -p /work && cp -a /src/. /work/ && cd /work && make packages && make lint && make test-unit && make iso && mkdir -p /src/build && cp -f /work/build/algothix-os-lite-amd64.iso /work/build/SHA256SUMS /src/build/'
```
