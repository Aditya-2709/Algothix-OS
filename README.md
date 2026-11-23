# Algothix OS (ALX) Lite

A fast, lightweight, Debian-based Linux distribution for programming and multitasking on old hardware (2–4 GB RAM, 64-bit x86_64 CPU, HDD).

## Status

- **Base:** Debian 13 (`trixie`, amd64) with `main` and `non-free-firmware`
- **Current milestone:** M1 — Minimal bootable console ISO (`alx-base`)
- **License:** GPL-3.0-or-later (see `LICENSE`)

## Repository Layout

- `auto/` — `live-build` entry scripts (`config`, `build`, `clean`)
- `config/` — `live-build` package lists, chroot hooks, includes, and bootloader branding
- `packages/` — Debian source packages for ALX components (`alx-base`, etc.)
- `ansible/` — Fleet management roles (planned for M7)
- `tests/` — Automated unit (`bats`), QEMU smoke tests, and hardware checklists
- `ci/` — Build, lint, and environment setup scripts
- `.github/workflows/` — GitHub Actions CI pipeline
- `docs/` — Architecture, engineering decisions (`DECISIONS.md`), and third-party packages (`THIRD_PARTY.md`)

## Quick Start

### 1. Prepare the build environment

Using Docker (recommended):

```bash
make docker-build
```

Or on a Debian 13 (`trixie`) host/VM:

```bash
sudo ./ci/setup-env.sh
```

### 2. Run targets

```bash
make help        # Show available targets
make lint        # Run shellcheck and lintian
make packages    # Build ALX .deb packages into build/repo
make iso         # Build the bootable hybrid ISO (BIOS + UEFI)
make test        # Run bats unit tests and QEMU BIOS/UEFI smoke tests
make clean       # Clean build artifacts
```

To build inside the Docker container (requires `--privileged` for `live-build` chroot/loop mounts):

```bash
docker run --rm --privileged -v "$(pwd):/src" -w /src alx-builder make packages iso
```
